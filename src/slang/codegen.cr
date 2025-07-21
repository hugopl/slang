require "./visitor"

module Slang
  class Codegen < Visitor
    private getter str : String::Builder
    private getter buffer_name : String

    delegate to_s, to: @str

    def initialize(@buffer_name = DEFAULT_BUFFER_NAME, @str : String::Builder = String::Builder.new)
    end

    def visit(node : Nodes::Doctype)
      str << "#{buffer_name} << \"<!DOCTYPE #{node.value}>\"\n"
    end

    def visit(node : Nodes::Comment)
      return unless node.visible

      str << "#{buffer_name} << \"\n\"\n" unless str.empty?
      str << "#{buffer_name} << \"#{node.indentation}\"\n" if node.indent?
      str << "#{buffer_name} << \"<!--\"\n"
      str << "#{buffer_name} << \"[#{node.conditional}]>\"\n" if node.conditional?
      str << "#{buffer_name} << \"#{node.value}\"\n" if node.value
      if node.children?
        visit_children(node)
        str << "#{buffer_name} << \"\n#{node.indentation}\"\n"
      end
      str << "#{buffer_name} << \"<![endif]\"\n" if node.conditional?
      str << "#{buffer_name} << \"-->\"\n"
    end

    def visit(node : Nodes::Element)
      str << "#{buffer_name} << \"\n\"\n" unless str.empty?
      str << "#{buffer_name} << \"#{node.indentation}\"\n" if node.indent?
      str << "#{buffer_name} << \"<#{node.name}\"\n"
      str << "#{buffer_name} << \" id=\\\"#{node.id}\\\"\"\n" if node.id
      c_names = node.generate_class_names
      if c_names && c_names != ""
        str << "#{buffer_name} << \" class\"\n"
        str << "#{buffer_name} << \"=\\\"\"\n"
        str << "(\"#{c_names}\").to_s #{buffer_name}\n"
        str << "#{buffer_name} << \"\\\"\"\n"
      end
      node.attributes.each do |name, value|
        str << "unless #{value} == false\n" # remove the attribute if value evaluates to false
        str << "#{buffer_name} << \" #{name}\"\n"
        str << "unless #{value} == true\n" # remove the value if value evaluates to true
        # any other attribute value.
        str << "#{buffer_name} << \"=\\\"\"\n"
        str << "#{buffer_name} << (#{value}).to_s.gsub(/\"/,\"&quot;\")\n"
        str << "#{buffer_name} << \"\\\"\"\n"
        str << "end\n"
        str << "end\n"
      end
      str << "#{buffer_name} << \">\"\n"
      visit_children(node)
      if !node.self_closing?
        if node.children? && !node.only_inline_children?
          str << "#{buffer_name} << \"\n\"\n"
          str << "#{buffer_name} << \"#{node.indentation}\"\n" if node.indent?
        end
        str << "#{buffer_name} << \"</#{node.name}>\"\n"
      end
    end

    def visit(node : Nodes::Text)
      str << "#{buffer_name} << \"\n\"\n" unless str.empty? || node.inline
      str << "#{buffer_name} << \"#{node.indentation}\"\n" if node.indent?
      str << "#{buffer_name} << "

      # Escaping.
      if node.escaped && node.parent.allow_children_to_escape?
        str << "HTML.escape("
      end

      # This is an output (code) token and has children
      if node.token.type.output? && node.children?
        sub_buffer_name = "#{buffer_name}#{Random::Secure.hex(8)}"
        str << "(#{node.value}\nString.build do |#{sub_buffer_name}|\n"
        sub_codegen = Codegen.new(sub_buffer_name, str)
        node.children.each do |child_node|
          child_node.accept(sub_codegen)
        end
        str << "end\nend)"
      else
        str << "(#{node.value})"
      end

      # escaping, need to close HTML.escape
      if node.escaped && node.parent.allow_children_to_escape?
        str << ".to_s)"
      end
      str << ".to_s\n"

      if !node.token.type.output? && node.children?
        visit_children(node)
      end
    end

    def visit(node : Nodes::Control)
      str << "#{node.value}\n"
      visit_children(node)
      node.branches.each do |branch|
        branch.accept(self)
      end
      str << "end\n" if node.endable?
    end
  end
end
