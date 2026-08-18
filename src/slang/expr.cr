module Slang
  module Expr
    abstract class Node
    end

    class Var < Node
      getter name : String

      def initialize(@name)
      end
    end

    class Literal < Node
      alias Value = String | Int64 | Float64 | Bool | Nil

      getter value : Value

      def initialize(@value)
      end
    end

    class Access < Node
      getter base : Node
      getter member : String

      def initialize(@base, @member)
      end
    end

    class Index < Node
      getter base : Node
      getter index : Node

      def initialize(@base, @index)
      end
    end

    class BinaryOp < Node
      getter op : String
      getter left : Node
      getter right : Node

      def initialize(@op, @left, @right)
      end
    end

    class UnaryOp < Node
      getter op : String
      getter operand : Node

      def initialize(@op, @operand)
      end
    end

    # receiver is nil for a bare call (`helper(x)`); set for a method call
    # (`user.posts(1)`) — the design doc's Call(callee, args) shape doesn't
    # account for a receiver, but ObjWrapper#call dispatch needs one to know
    # what it's calling the method on.
    class Call < Node
      getter receiver : Node?
      getter callee : String
      getter args : Array(Node)

      def initialize(@callee, @args = [] of Node, @receiver = nil)
      end
    end
  end
end
