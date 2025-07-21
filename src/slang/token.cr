module Slang
  class Token
    enum Type
      EOF
      Newline
      Text
      Element
      Doctype
      Control
      Output
      HTML
      Comment
    end

    property type : Type = :EOF
    property line_number : Int32 = 0
    property column_number : Int32 = 0
    # elements
    property name : String = "div"
    property attributes : Hash(String, String | Set(String))
    property id : String?

    property value : String?
    property escaped : Bool = true
    property inline : Bool = false
    property visible : Bool = true
    property conditional : String = ""

    def initialize
      @attributes = {} of String => (String | Set(String))
      @attributes["class"] = Set(String).new
    end

    def add_attribute(name, value, interpolate)
      if name == "class"
        value = "\#{#{value}}" if interpolate
        (@attributes["class"].as Set) << value
      else
        @attributes[name] = value
      end
    end
  end
end
