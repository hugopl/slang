require "html"
require "./slang/version"
require "./slang/node"
require "./slang/document"
require "./slang/lexer"
require "./slang/parser"
require "./slang/token"
require "./slang/macros"
require "./slang/codegen"

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
end
