require "spec"
require "../src/slang"

require "./support/form_view"

I18N_CATALOGS = {
  "pt_BR" => Slang::Po.parse(File.read("spec/fixtures/locales/pt_BR.po")),
}

# Stand-in for a host application's t(): Slang only emits calls to it, it
# never implements it (see Codegen#translated_expr).
def t(msgid : String, lang : String) : String
  I18N_CATALOGS[lang]?.try(&.[msgid]?) || msgid
end

macro render_file(filename)
  String.build do |__str__|
    \{{ run("./support/process_file", {{filename}}, "__str__") }}
  end
end

macro render(slang)
  String.build do |__str__|
    \{{ run("./support/process", {{slang}}, "__str__") }}
  end
end

macro render_file_i18n(filename, lang)
  String.build do |__str__|
    \{{ run("./support/process_file_i18n", {{filename}}, "__str__", {{lang.stringify}}) }}
  end
end

macro render_i18n(slang, lang)
  String.build do |__str__|
    \{{ run("./support/process_i18n", {{slang}}, "__str__", {{lang.stringify}}) }}
  end
end

macro render_file_inline_i18n(filename, lang, locales_dir = "spec/fixtures/locales")
  String.build do |__str__|
    \{{ run("./support/process_file_inline_i18n", {{filename}}, "__str__", {{locales_dir}}, {{lang.stringify}}) }}
  end
end

macro render_inline_i18n(slang, lang, locales_dir = "spec/fixtures/locales")
  String.build do |__str__|
    \{{ run("./support/process_inline_i18n", {{slang}}, "__str__", {{locales_dir}}, {{lang.stringify}}) }}
  end
end
