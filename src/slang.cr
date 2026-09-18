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
require "./slang/po"

# require "./slang/*"

module Slang
  extend self
  DEFAULT_BUFFER_NAME = "__slang__"

  @@default_locale = "en_US"

  # The locale a template's own literal text is written in. Compared against
  # `lang_expr` at codegen time (see Codegen#translated_expr): rendering in
  # this locale skips every `t()` call and its lookup cost, so it stays the
  # cheapest path regardless of how many other locales exist.
  def default_locale : String
    @@default_locale
  end

  def default_locale=(value : String)
    @@default_locale = value
  end

  def process_string(slang, filename = "dummy.slang", buffer_name = DEFAULT_BUFFER_NAME, *, translate = false, lang_expr = "lang") : String
    document = Slang::Parser.new(slang).parse
    codegen = Codegen.new(buffer_name, translate: translate, lang_expr: lang_expr)
    document.accept(codegen)
    codegen.to_s
  end

  def process_file(filename, buffer_name = DEFAULT_BUFFER_NAME, *, translate = false, lang_expr = "lang")
    raise "Slang template: #{filename} doesn't exist." unless File.exists?(filename)
    process_string(File.read(filename), filename, buffer_name, translate: translate, lang_expr: lang_expr)
  end

  # Same output regardless of locale count: every translatable literal becomes
  # a `t(msgid, lang_expr)` call (fast-pathed when `lang_expr` matches
  # `default_locale`, see Codegen#translated_expr), so there is exactly one
  # codegen pass and no per-locale duplication of the template.
  def process_string_i18n(slang, filename = "dummy.slang", buffer_name = DEFAULT_BUFFER_NAME, lang_expr = "lang") : String
    process_string(slang, filename, buffer_name, translate: true, lang_expr: lang_expr)
  end

  def process_file_i18n(filename, buffer_name = DEFAULT_BUFFER_NAME, lang_expr = "lang")
    raise "Slang template: #{filename} doesn't exist." unless File.exists?(filename)
    process_string_i18n(File.read(filename), filename, buffer_name, lang_expr)
  end

  # The original per-locale approach: every `<lang>.po` file in `locales_dir`
  # becomes one `when` branch, each a full Codegen pass with that locale's
  # strings resolved and folded directly into the static buffer — no `t()`,
  # no runtime hash lookup, one string compare total per render. The
  # source-language text (untouched) is the `else` fallback, matching
  # gettext's own rule: a missing translation renders the msgid itself.
  #
  # Trade-off vs `process_string_i18n`: zero runtime translation lookup cost,
  # but one codegen pass per locale, so compile time/memory scales with
  # locale-count × template-count. Prefer `process_string_i18n` unless that
  # trade is worth it for your template set.
  def process_string_inline_i18n(slang, filename = "dummy.slang", buffer_name = DEFAULT_BUFFER_NAME, locales_dir = "locales", lang_expr = "lang") : String
    locales = Dir.exists?(locales_dir) ? Dir.glob(File.join(locales_dir, "*.po")).map { |path| File.basename(path, ".po") }.sort! : [] of String
    return process_string(slang, filename, buffer_name) if locales.empty?

    # Each pass parses `slang` fresh: Codegen (via Nodes::Element#generate_class_names)
    # mutates the AST it visits, so the same parsed Document can't be visited twice.
    String.build do |io|
      io << "case " << lang_expr << "\n"
      locales.each do |lang|
        catalog = Po.parse(File.read(File.join(locales_dir, "#{lang}.po")))
        codegen = Codegen.new(buffer_name, catalog: catalog)
        Slang::Parser.new(slang).parse.accept(codegen)
        io << "when " << lang.inspect << "\n" << codegen.to_s
      end
      io << "else\n"
      fallback = Codegen.new(buffer_name)
      Slang::Parser.new(slang).parse.accept(fallback)
      io << fallback.to_s
      io << "end\n"
    end
  end

  def process_file_inline_i18n(filename, buffer_name = DEFAULT_BUFFER_NAME, locales_dir = "locales", lang_expr = "lang")
    raise "Slang template: #{filename} doesn't exist." unless File.exists?(filename)
    process_string_inline_i18n(File.read(filename), filename, buffer_name, locales_dir, lang_expr)
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
