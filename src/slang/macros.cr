module Slang
  macro embed(filename, io_name)
    \{{ run("slang/slang/process", {{filename}}, {{io_name.id.stringify}}) }}
  end

  # Like `embed`, but resolves every translatable literal through a `t(msgid, lang)`
  # call the host application provides, instead of baking one language into
  # the binary. Rendering in `Slang.default_locale` skips `t()` entirely —
  # see `Codegen#translated_expr`.
  macro embed_i18n(filename, io_name, lang)
    \{{ run("slang/slang/process", "--i18n", {{filename}}, {{io_name.id.stringify}}, {{lang.stringify}}) }}
  end

  # The original per-locale approach (see `Slang.process_string_inline_i18n`):
  # resolves every translatable literal against `locales_dir`'s `.po`
  # catalogs at compile time, with zero runtime translation lookup — at the
  # cost of one full codegen pass per locale. Prefer `embed_i18n` unless that
  # trade is worth it for your template set.
  macro embed_inline_i18n(filename, io_name, lang, locales_dir = "locales")
    \{{ run("slang/slang/process", "--inline-i18n", {{filename}}, {{io_name.id.stringify}}, {{locales_dir}}, {{lang.stringify}}) }}
  end

  # Use in a class
  macro file(filename)
    def to_s(__slang__)
      Slang.embed {{filename}}, "__slang__"
    end
  end

  macro file_i18n(filename)
    def to_s(__slang__, lang)
      Slang.embed_i18n {{filename}}, "__slang__", lang
    end
  end

  macro file_inline_i18n(filename, locales_dir = "locales")
    def to_s(__slang__, lang)
      Slang.embed_inline_i18n {{filename}}, "__slang__", lang, {{locales_dir}}
    end
  end
end
