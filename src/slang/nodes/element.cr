module Slang
  module Nodes
    class Element < Node
      SELF_CLOSING_TAGS = {"area", "base", "br", "col", "embed", "hr", "img", "input", "keygen", "link", "menuitem", "meta", "param", "source", "track", "wbr"}
      RAW_TEXT_TAGS     = %w(script style)

      delegate name, id, attributes, to: @token

      def generate_class_names
        names = attributes.delete("class").as Set
        names.join(" ")
      end

      def allow_children_to_escape?
        !RAW_TEXT_TAGS.includes?(name)
      end

      def only_inline_children?
        children.all? { |n| n.inline }
      end

      def self_closing?
        SELF_CLOSING_TAGS.includes?(name)
      end
    end
  end
end
