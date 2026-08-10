require "html"
require "./slang/version"
require "./slang/node"
require "./slang/document"
require "./slang/lexer"
require "./slang/parser"
require "./slang/token"
require "./slang/macros"
require "./slang/codegen"
require "./slang/extractor"

# require "./slang/*"

module Slang
  extend self
  DEFAULT_BUFFER_NAME = "__slang__"

  def process_string(slang, filename = "dummy.slang", buffer_name = DEFAULT_BUFFER_NAME, *, translate = false) : String
    document = Slang::Parser.new(slang).parse
    codegen = Codegen.new(buffer_name, translate: translate)
    document.accept(codegen)
    codegen.to_s
  end

  def process_file(filename, buffer_name = DEFAULT_BUFFER_NAME, *, translate = false)
    raise "Slang template: #{filename} doesn't exist." unless File.exists?(filename)
    process_string(File.read(filename), filename, buffer_name, translate: translate)
  end

  # Lists this file's translatable strings as .pot entries; does not touch
  # what process_file generates.
  def extract_strings(slang, filename = "dummy.slang") : String
    document = Slang::Parser.new(slang).parse
    extractor = Extractor.new
    document.accept(extractor)

    extractor.entries.map { |entry|
      String.build do |io|
        io << "#. #{entry.comment}\n" if entry.comment
        io << "#: #{filename}:#{entry.line_number}\n"
        io << "msgid #{entry.msgid.inspect}\n"
        io << "msgstr \"\"\n"
      end
    }.join("\n")
  end

  def extract_strings_from_file(filename) : String
    raise "Slang template: #{filename} doesn't exist." unless File.exists?(filename)
    extract_strings(File.read(filename), filename)
  end
end
