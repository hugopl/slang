module Slang
  macro embed(filename, io_name)
    \{{ run("slang/slang/process", {{filename}}, {{io_name.id.stringify}}) }}
  end

  # Like `embed`, but renders every locale in `locales_dir` (one `<lang>.po`
  # file each) as its own static branch, dispatching on `lang` at runtime.
  macro embed_i18n(filename, io_name, lang, locales_dir = "locales")
    \{{ run("slang/slang/process", "--i18n", {{filename}}, {{io_name.id.stringify}}, {{locales_dir}}, {{lang.stringify}}) }}
  end

  # Use in a class
  macro file(filename)
    def to_s(__slang__)
      Slang.embed {{filename}}, "__slang__"
    end
  end

  macro file_i18n(filename, locales_dir = "locales")
    def to_s(__slang__, lang)
      Slang.embed_i18n {{filename}}, "__slang__", lang, {{locales_dir}}
    end
  end
end
