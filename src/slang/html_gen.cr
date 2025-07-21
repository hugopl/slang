module Slang
  class HTMLGen < Visitor
    @context : Context
    @io : String::Builder

    delegate to_s, to: @io

    def initialize(@context : Context)
      @io = String::Builder.new
    end

    def visit(node : Nodes::Doctype)
      @io << "<!DOCTYPE " << node.value << ">"
    end

    def visit(node : Nodes::Comment)
    end

    def visit(node : Nodes::Element)
      @io << "\n" unless @io.empty?
      @io << node.indentation if node.indent?
      @io << "<" << node.name
      @io << " id=\"" << node.id << "\"" if node.id
      c_names = node.generate_class_names
      if c_names && c_names != ""
        @io << " class=\"" << c_names << "\""
      end
      node.attributes.each do |name, value|
        unless value == false # remove the attribute if value evaluates to false
          @io << " " << name
          unless value == true # remove the value if value evaluates to true
            # any other attribute value.
            @io << "=" << value.to_s
          end
        end
      end

      @io << ">"
      visit_children(node)
      if !node.self_closing?
        if node.children? && !node.only_inline_children?
          @io << "\n"
          @io << node.indentation if node.indent?
        end
        @io << "</" << node.name << ">"
      end
    end

    def visit(node : Nodes::Text)
      @io << "\n" unless @io.empty? || node.inline
      @io << node.indentation if node.indent?

      # Escaping.
      # if node.escaped && node.parent.allow_children_to_escape?
      #   str << "HTML.escape("
      # end

      # This is an output (code) token and has children
      if node.token.type.output? && node.children?
        # sub_buffer_name = "#{buffer_name}#{Random::Secure.hex(8)}"
        # str << "(#{node.value}\nString.build do |#{sub_buffer_name}|\n"
        # sub_codegen = Codegen.new(sub_buffer_name, str)
        # node.children.each do |child_node|
        #   child_node.accept(sub_codegen)
        # end
        # str << "end\nend)"
      else
        @io << node.value
      end

      # escaping, need to close HTML.escape
      # if node.escaped && node.parent.allow_children_to_escape?
      #   str << ".to_s)"
      # end
      # str << ".to_s\n"

      if !node.token.type.output? && node.children?
        visit_children(node)
      end
    end

    def visit(node : Nodes::Control)
    end
  end
end
