require "./visitor"
require "./translatable"
require "html"

module Slang
  class Codegen < Visitor
    private getter str : String::Builder
    private getter buffer_name : String
    @pending_static : String = ""
    @no_translate_depth = 0

    # `translate` and `catalog` are two independent, mutually exclusive ways
    # to resolve the same translatable literals — a Codegen only ever uses
    # one of them. Both are off/nil by default: Codegen is shared by anyone
    # embedding Slang templates, and most consumers have neither a t() method
    # nor per-locale catalogs.
    #
    # `translate` (see process.cr's --i18n flag) emits a `t(msgid, lang)` call
    # for every translatable literal — one codegen pass total, no matter how
    # many locales exist. `lang_expr` is spliced verbatim into the generated
    # code (it is whatever expression the caller passed as `lang`, not
    # necessarily a variable literally named "lang") and used two ways: as the
    # value handed to `t()`, and to compare against `Slang.default_locale` —
    # when they match, the template's own literal text already *is* that
    # locale's text, so `t()` is skipped entirely (see `translated_expr`).
    #
    # `catalog` (see process.cr's --inline-i18n flag) resolves every
    # translatable literal to its `msgstr` (or the source string, gettext-
    # style) right here at codegen time and folds it straight into the static
    # buffer — no `t()` call, no runtime lookup at all, but one full codegen
    # pass per locale (see `Slang.process_string_inline_i18n`).
    def initialize(@buffer_name = DEFAULT_BUFFER_NAME, @str : String::Builder = String::Builder.new, @translate : Bool = false, @lang_expr : String = "lang", @catalog : Hash(String, String)? = nil)
    end

    def to_s : String
      flush_static
      @str.to_s
    end

    # Flush the accumulated static string as a single io << call.
    # Protected so sub-codegens can be flushed by the parent.
    # Multi-line strings are split at newline boundaries and emitted as adjacent
    # string literals joined by \ continuation so each HTML line is readable.
    protected def flush_static
      return if @pending_static.empty?

      if @pending_static.includes?('\n')
        parts = [] of String
        @pending_static.each_line(chomp: false) { |line| parts << line }
        indent = " " * (buffer_name.size + 4)
        str << "#{buffer_name} << #{parts.map(&.inspect).join(" \\\n#{indent}")}\n"
      else
        str << "#{buffer_name} << #{@pending_static.inspect}\n"
      end

      @pending_static = ""
    end

    private def emit_static(s : String)
      @pending_static += s
    end

    private def any_output?
      !str.empty? || !@pending_static.empty?
    end

    def visit(node : Nodes::Doctype)
      emit_static("<!DOCTYPE #{node.value}>")
    end

    def visit(node : Nodes::Comment)
      return unless node.visible

      emit_static("\n") if any_output?
      emit_static(node.indentation) if node.indent?
      emit_static("<!--")
      emit_static("[#{node.conditional}]>") if node.conditional?
      emit_static(node.value.to_s) if node.value
      if node.children?
        visit_children(node)
        emit_static("\n#{node.indentation}")
      end
      emit_static("<![endif]") if node.conditional?
      emit_static("-->")
    end

    def visit(node : Nodes::Element)
      emit_static("\n") if any_output?
      emit_static(node.indentation) if node.indent?
      emit_static("<#{node.name}")
      emit_static(" id=\"#{node.id}\"") if node.id
      c_names = node.generate_class_names
      if c_names && c_names != ""
        # c_names may contain Crystal interpolation (e.g. "#{klass}"), so we
        # cannot use emit_static+inspect here — that would escape the #{.
        flush_static
        str << "#{buffer_name} << \" class=\\\"\"\n"
        str << "(\"#{c_names}\").to_s #{buffer_name}\n"
        str << "#{buffer_name} << \"\\\"\"\n"
      end
      render_attributes(node)
      emit_static(">")
      if Nodes::Element::NO_TRANSLATE_TAGS.includes?(node.name)
        @no_translate_depth += 1
        visit_children(node)
        @no_translate_depth -= 1
      else
        visit_children(node)
      end
      render_element_close(node)
    end

    private def render_attributes(node : Nodes::Element)
      node.attributes.each do |name, attr|
        case attr
        when Token::AttributeValue
          render_attribute(name, attr)
        end
      end
    end

    private def render_attribute(name : String, attr : Token::AttributeValue)
      return render_dynamic_attribute(name, attr) unless attr.literal

      text = Translatable::ATTRIBUTES.includes?(name) ? Translatable.literal_text(attr.value) : nil

      if text && @catalog
        emit_static(" #{name}=\"#{resolve_translation(text).gsub('"', "&quot;")}\"")
        return
      end

      if text && @translate
        flush_static
        str << "#{buffer_name} << \" #{name}=\\\"\"\n"
        str << "#{buffer_name} << #{translated_expr(text)}.gsub(/\"/,\"&quot;\")\n"
        str << "#{buffer_name} << \"\\\"\"\n"
        return
      end

      # Value is a quoted template literal — strip surrounding quotes,
      # pre-compute the &quot; escaping, and fold into the static buffer.
      inner = attr.value[1..-2]
      emit_static(" #{name}=\"#{inner.gsub('"', "&quot;")}\"")
    end

    private def render_dynamic_attribute(name : String, attr : Token::AttributeValue)
      flush_static
      str << "unless #{attr.value} == false\n"
      emit_static(" #{name}")
      flush_static
      str << "unless #{attr.value} == true\n"
      emit_static("=\"")
      flush_static
      str << "#{buffer_name} << (#{attr.value}).to_s.gsub(/\"/,\"&quot;\")\n"
      emit_static("\"")
      flush_static
      str << "end\n"
      str << "end\n"
    end

    private def render_element_close(node : Nodes::Element)
      if !node.self_closing?
        if node.children? && !node.only_inline_children?
          emit_static("\n")
          emit_static(node.indentation) if node.indent?
        end
        emit_static("</#{node.name}>")
      end
    end

    def visit(node : Nodes::Text)
      emit_static("\n") if any_output? && !node.inline
      emit_static(node.indentation) if node.indent?

      return if try_emit_translated_text(node)
      return if try_emit_literal_text(node)

      emit_dynamic_text(node)
    end

    private def try_emit_translated_text(node : Nodes::Text) : Bool
      return false if @no_translate_depth > 0
      return false unless text = Translatable.literal_text(node.value)

      return emit_catalog_text(node, text) if @catalog
      return emit_translate_text(node, text) if @translate
      false
    end

    private def emit_catalog_text(node : Nodes::Text, text : String) : Bool
      resolved = resolve_translation(text)
      resolved = HTML.escape(resolved) if node.escaped && node.parent.allow_children_to_escape?
      emit_static(resolved)
      visit_children(node) if node.children?
      true
    end

    private def emit_translate_text(node : Nodes::Text, text : String) : Bool
      flush_static
      str << "#{buffer_name} << "
      str << "HTML.escape(" if node.escaped && node.parent.allow_children_to_escape?
      str << translated_expr(text)
      str << ".to_s)" if node.escaped && node.parent.allow_children_to_escape?
      str << ".to_s\n"
      visit_children(node) if node.children?
      true
    end

    # `lang_expr` already *is* `Slang.default_locale`'s text in the common
    # case, so the fast path skips `t()` (and whatever lookup cost it has)
    # entirely and uses the template's own literal instead.
    private def translated_expr(text : String) : String
      "(#{@lang_expr} == Slang.default_locale ? #{text.inspect} : t(#{text.inspect}, #{@lang_expr}))"
    end

    # Looks up `msgid` in the current locale's catalog; gettext semantics
    # apply, so a missing or empty msgstr falls back to the source string.
    private def resolve_translation(msgid : String) : String
      return msgid unless catalog = @catalog
      translation = catalog[msgid]?
      translation && !translation.empty? ? translation : msgid
    end

    private def try_emit_literal_text(node : Nodes::Text) : Bool
      # For Text-type tokens (| and ' syntax) whose value is a plain Crystal
      # string literal with no escape sequences and no #{} interpolation, we
      # can resolve the content and any HTML escaping at codegen time.
      if node.token.type.text?
        if (value = node.value) && value.size >= 2 && value[0] == '"' && value[-1] == '"'
          inner = value[1..-2]
          unless inner.includes?('\\') || inner.includes?("\#{")
            text = node.escaped && node.parent.allow_children_to_escape? ? HTML.escape(inner) : inner
            emit_static(text)
            visit_children(node) if node.children?
            return true
          end
        end
      end
      false
    end

    private def emit_dynamic_text(node : Nodes::Text)
      flush_static
      str << "#{buffer_name} << "

      if node.escaped && node.parent.allow_children_to_escape?
        str << "HTML.escape("
      end

      if node.token.type.output? && node.children?
        sub_buffer_name = "#{buffer_name}#{Random::Secure.hex(8)}"
        str << "(#{node.value}\nString.build do |#{sub_buffer_name}|\n"
        sub_codegen = Codegen.new(sub_buffer_name, str, @translate, @lang_expr, @catalog)
        node.children.each do |child_node|
          child_node.accept(sub_codegen)
        end
        sub_codegen.flush_static
        str << "end\nend)"
      else
        str << "(#{node.value})"
      end

      if node.escaped && node.parent.allow_children_to_escape?
        str << ".to_s)"
      end
      str << ".to_s\n"

      if !node.token.type.output? && node.children?
        visit_children(node)
      end
    end

    def visit(node : Nodes::Control)
      flush_static
      str << "#{node.value}\n"
      visit_children(node)
      node.branches.each do |branch|
        branch.accept(self)
      end
      flush_static
      str << "end\n" if node.endable?
    end
  end
end
