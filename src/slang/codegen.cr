require "./visitor"
require "html"

module Slang
  class Codegen < Visitor
    private getter str : String::Builder
    private getter buffer_name : String
    @pending_static : String = ""

    def initialize(@buffer_name = DEFAULT_BUFFER_NAME, @str : String::Builder = String::Builder.new)
    end

    def to_s : String
      flush_static
      @str.to_s
    end

    # Flush the accumulated static string as a single io << call.
    # Protected so sub-codegens can be flushed by the parent.
    protected def flush_static
      unless @pending_static.empty?
        str << "#{buffer_name} << #{@pending_static.inspect}\n"
        @pending_static = ""
      end
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
      node.attributes.each do |name, attr|
        case attr
        when Token::AttributeValue
          if attr.literal
            # Value is a quoted template literal — strip surrounding quotes,
            # pre-compute the &quot; escaping, and fold into the static buffer.
            inner = attr.value[1..-2]
            emit_static(" #{name}=\"#{inner.gsub('"', "&quot;")}\"")
          else
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
        end
      end
      emit_static(">")
      visit_children(node)
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
            return
          end
        end
      end

      flush_static
      str << "#{buffer_name} << "

      if node.escaped && node.parent.allow_children_to_escape?
        str << "HTML.escape("
      end

      if node.token.type.output? && node.children?
        sub_buffer_name = "#{buffer_name}#{Random::Secure.hex(8)}"
        str << "(#{node.value}\nString.build do |#{sub_buffer_name}|\n"
        sub_codegen = Codegen.new(sub_buffer_name, str)
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
