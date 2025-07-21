require "./context"

module Slang
  macro embed(filename, io_name)
    \{{ run("slang/slang/process", {{filename}}, {{io_name.id.stringify}}) }}
  end

  # This will render a Slang file with the given context.
  #
  # If the `slang_at_runtime` flag is set, it will read the file at runtime.
  # Otherwise, it will embed the file at compile time.
  #
  # The `context` is a NamedTuple with variables accessible in the Slang file.
  macro render(filename, context, io_name)
    {% if flag?(:slang_at_runtime) %}H
      File.open({{ filename }}) do |file|
        Slang.render_file({{ filename }}, Context.new(context))
      end
    {% else %}
      {% for key, value in context %}
        {{ key }} = {{ value }}
        Slang.embed {{ filename }}, {{ io_name }}
      {% end %}
    {% end %}
    puts {{ filename }}
  end

  # Use in a class
  macro file(filename)
    def to_s(__slang__)
      Slang.embed {{filename}}, "__slang__"
    end
  end
end
