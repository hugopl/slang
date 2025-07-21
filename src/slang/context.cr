module Slang
  struct Any
    @raw : String | Nil

    def initialize(@raw)
    end
  end

  class Context
    @data : Hash(String, Any)

    def initialize(locals : NamedTuple)
      @data = Hash(String, Any).new
      locals.each do |key, value|
        @data[key.to_s] = Any.new(value)
      end
    end
  end
end
