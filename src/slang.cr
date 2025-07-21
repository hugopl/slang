require "html"
require "./slang/version"
require "./slang/node"
require "./slang/document"
require "./slang/lexer"
require "./slang/parser"
require "./slang/token"
require "./slang/macros"
require "./slang/codegen"
require "./slang/html_gen"

# require "./slang/*"

module Slang
  extend self
  DEFAULT_BUFFER_NAME = "__slang__"

  def process_string(slang, filename = "dummy.slang", buffer_name = DEFAULT_BUFFER_NAME) : String
    document = Slang::Parser.new(slang).parse
    codegen = Codegen.new(buffer_name)
    document.accept(codegen)
    codegen.to_s
  end

  def process_file(filename, buffer_name = DEFAULT_BUFFER_NAME)
    raise "Slang template: #{filename} doesn't exist." unless File.exists?(filename)
    process_string(File.read(filename), filename, buffer_name)
  end

  def render_content(slang : String, locals : NamedTuple)
    document = Slang::Parser.new(slang).parse
    htmlgen = HTMLGen.new(Context.new(locals))
    document.accept(htmlgen)
    htmlgen.to_s
  end

  def render_file(filename : String | Path, context : NamedTuple)
    File.open(filename) { |file| render(file, context) }
  end
end
