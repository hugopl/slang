require "html"
require "colorize"
require "benchmark"

def p(a)
  a + "-#{Process.pid}"
end

def old
  String.build do |io|
    io << "<!DOCTYPE html>"
    io << "
"
    io << "<html"
    io << ">"
    io << "
"
    io << "  "
    io << "<head"
    io << ">"
    io << "
"
    io << "    "
    io << "<meta"
    unless "viewport" == false
      io << " name"
      unless "viewport" == true
        io << "=\""
        io << ("viewport").to_s.gsub(/"/, "&quot;")
        io << "\""
      end
    end
    unless "width=device-width,initial-scale=1.0" == false
      io << " content"
      unless "width=device-width,initial-scale=1.0" == true
        io << "=\""
        io << ("width=device-width,initial-scale=1.0").to_s.gsub(/"/, "&quot;")
        io << "\""
      end
    end
    io << ">"
    io << "
"
    io << "    "
    io << "<title"
    io << ">"
    io << HTML.escape(("This is a title").to_s).to_s
    io << "</title>"
    io << "
"
    io << "    "
    io << "<style"
    io << ">"
    io << "
"
    io << "      "
    io << ("h1 {color: red;}").to_s
    io << "
"
    io << "      "
    io << ("p {color: green;}").to_s
    io << "
"
    io << "    "
    io << "</style>"
    io << "
"
    io << "    "
    io << "<style"
    io << ">"
    io << ("h2 {color: blue;}").to_s
    io << "</style>"
    io << "
"
    io << "  "
    io << "</head>"
    io << "
"
    io << "  "
    io << "<body"
    io << ">"
    io << "
"
    io << "    "
    io << "<!--"
    io << "Multi-line comment"
    io << "
"
    io << "      "
    io << "<span"
    io << ">"
    io << HTML.escape(("this is wrapped in a comment").to_s).to_s
    io << "</span>"
    io << "
    "
    io << "-->"
    io << "
"
    io << "    "
    io << "<!--"
    io << "[if IE]>"
    io << "
"
    io << "      "
    io << "<p"
    io << ">"
    io << HTML.escape(("Dat browser is old.").to_s).to_s
    io << "</p>"
    io << "
    "
    io << "<![endif]"
    io << "-->"
    io << "
"
    io << "    "
    io << "<h1"
    io << ">"
    io << HTML.escape(("This is a slang file").to_s).to_s
    io << "</h1>"
    io << "
"
    io << "    "
    io << "<h2"
    io << ">"
    io << HTML.escape(("This is blue").to_s).to_s
    io << "</h2>"
    io << "
"
    io << "    "
    io << "<span"
    io << " id=\"some-id\""
    io << " class"
    io << "=\""
    ("classname").to_s io
    io << "\""
    io << ">"
    io << "
"
    io << "      "
    io << "<div"
    io << " id=\"hello\""
    io << " class"
    io << "=\""
    ("world world2").to_s io
    io << "\""
    io << ">"
    some_var = "hello world haha"
    io << "
"
    io << "        "
    io << "<span"
    io << ">"
    io << "
"
    io << "          "
    io << "<span"
    unless some_var == false
      io << " data-some-var"
      unless some_var == true
        io << "=\""
        io << (some_var).to_s.gsub(/"/, "&quot;")
        io << "\""
      end
    end
    unless "fun" == false
      io << " two-attr"
      unless "fun" == true
        io << "=\""
        io << ("fun").to_s.gsub(/"/, "&quot;")
        io << "\""
      end
    end
    io << ">"
    io << HTML.escape(("and a #{p("hello")}").to_s).to_s
    io << "</span>"
    io << "
"
    io << "          "
    io << "<span"
    io << ">"
    io << "
"
    io << "            "
    io << "<span"
    io << " class"
    io << "=\""
    ("deep_nested").to_s io
    io << "\""
    io << ">"
    io << "
"
    io << "              "
    io << "<p"
    io << ">"
    io << "
"
    io << "                "
    io << HTML.escape(("text inside of <p>").to_s).to_s
    io << "
"
    io << "              "
    io << "</p>"
    io << "
"
    io << "              "
    io << HTML.escape((Process.pid).to_s).to_s
    io << "
"
    io << "              "
    io << HTML.escape(("text node").to_s).to_s
    io << "
"
    io << "              "
    io << HTML.escape(("other text node ").to_s).to_s
    io << "
"
    io << "            "
    io << "</span>"
    io << "
"
    io << "          "
    io << "</span>"
    io << "
"
    io << "        "
    io << "</span>"
    io << "
"
    io << "        "
    io << "<span"
    io << " class"
    io << "=\""
    ("alongside").to_s io
    io << "\""
    unless Process.pid == false
      io << " pid"
      unless Process.pid == true
        io << "=\""
        io << (Process.pid).to_s.gsub(/"/, "&quot;")
        io << "\""
      end
    end
    io << ">"
    io << "
"
    io << "          "
    io << "<custom-tag"
    io << " id=\"with-id\""
    unless "#{Process.pid}" == false
      io << " pid"
      unless "#{Process.pid}" == true
        io << "=\""
        io << ("#{Process.pid}").to_s.gsub(/"/, "&quot;")
        io << "\""
      end
    end
    io << ">"
    ["ah", "oh"].each do |s|
      io << "
"
      io << "            "
      io << "<span"
      io << ">"
      io << HTML.escape((s).to_s).to_s
      io << "</span>"
    end
    io << "
"
    io << "          "
    io << "</custom-tag>"
    io << "
"
    io << "        "
    io << "</span>"
    io << "
"
    io << "      "
    io << "</div>"
    io << "
"
    io << "    "
    io << "</span>"
    io << "
"
    io << "    "
    io << "<div"
    io << " id=\"amazing-div\""
    unless "hello" == false
      io << " some-attr"
      unless "hello" == true
        io << "=\""
        io << ("hello").to_s.gsub(/"/, "&quot;")
        io << "\""
      end
    end
    io << ">"
    io << "</div>"
    io << "
"
    io << "    "
    io << "<!--"
    io << "This is a visible comment"
    io << "-->"
    io << "
"
    io << "    "
    io << "<script"
    io << ">"
    io << ("var num1 = 8*4;").to_s
    io << "</script>"
    io << "
"
    io << "    "
    io << "<script"
    io << ">"
    io << "
"
    io << "      "
    io << ("var num2 = 8*3;").to_s
    io << "
"
    io << "      "
    io << ("alert(\"8 * 3 + 8 * 4 = \" + (num1 + num2));").to_s
    io << "
"
    io << "    "
    io << "</script>"
    io << "
"
    io << "  "
    io << "</body>"
    io << "
"
    io << "</html>"
  end
end

def new
  String.build do |io|
    io << "<!DOCTYPE html>
<html>
  <head>
    <meta name=\"viewport\""
    unless "width=device-width,initial-scale=1.0" == false
      io << " content"
      unless "width=device-width,initial-scale=1.0" == true
        io << "=\""
        io << ("width=device-width,initial-scale=1.0").to_s.gsub(/"/, "&quot;")
        io << "\""
      end
    end
    io << ">"
    io << "
"
    io << "    "
    io << "<title"
    io << ">"
    io << HTML.escape(("This is a title").to_s).to_s
    io << "</title>"
    io << "
"
    io << "    "
    io << "<style"
    io << ">"
    io << "
"
    io << "      "
    io << ("h1 {color: red;}").to_s
    io << "
"
    io << "      "
    io << ("p {color: green;}").to_s
    io << "
"
    io << "    "
    io << "</style>"
    io << "
"
    io << "    "
    io << "<style"
    io << ">"
    io << ("h2 {color: blue;}").to_s
    io << "</style>"
    io << "
  </head>
  <body>
    <!--Multi-line comment
      <span>"
    io << HTML.escape(("this is wrapped in a comment").to_s).to_s
    io << "</span>"
    io << "
    "
    io << "-->"
    io << "
"
    io << "    "
    io << "<!--"
    io << "[if IE]>"
    io << "
"
    io << "      "
    io << "<p"
    io << ">"
    io << HTML.escape(("Dat browser is old.").to_s).to_s
    io << "</p>"
    io << "
    "
    io << "<![endif]"
    io << "-->"
    io << "
"
    io << "    "
    io << "<h1"
    io << ">"
    io << HTML.escape(("This is a slang file").to_s).to_s
    io << "</h1>"
    io << "
"
    io << "    "
    io << "<h2"
    io << ">"
    io << HTML.escape(("This is blue").to_s).to_s
    io << "</h2>"
    io << "
"
    io << "    "
    io << "<span"
    io << " id=\"some-id\""
    io << " class"
    io << "=\""
    ("classname").to_s io
    io << "\""
    io << ">"
    io << "
"
    io << "      "
    io << "<div"
    io << " id=\"hello\""
    io << " class"
    io << "=\""
    ("world world2").to_s io
    io << "\""
    io << ">"
    some_var = "hello world haha"
    io << "
"
    io << "        "
    io << "<span"
    io << ">"
    io << "
"
    io << "          "
    io << "<span"
    unless some_var == false
      io << " data-some-var"
      unless some_var == true
        io << "=\""
        io << (some_var).to_s.gsub(/"/, "&quot;")
        io << "\""
      end
    end
    unless "fun" == false
      io << " two-attr"
      unless "fun" == true
        io << "=\""
        io << ("fun").to_s.gsub(/"/, "&quot;")
        io << "\""
      end
    end
    io << ">"
    io << HTML.escape(("and a #{p("hello")}").to_s).to_s
    io << "</span>"
    io << "
"
    io << "          "
    io << "<span"
    io << ">"
    io << "
"
    io << "            "
    io << "<span"
    io << " class"
    io << "=\""
    ("deep_nested").to_s io
    io << "\""
    io << ">"
    io << "
"
    io << "              "
    io << "<p"
    io << ">"
    io << "
"
    io << "                "
    io << HTML.escape(("text inside of <p>").to_s).to_s
    io << "
"
    io << "              "
    io << "</p>"
    io << "
"
    io << "              "
    io << HTML.escape((Process.pid).to_s).to_s
    io << "
"
    io << "              "
    io << HTML.escape(("text node").to_s).to_s
    io << "
"
    io << "              "
    io << HTML.escape(("other text node ").to_s).to_s
    io << "
"
    io << "            "
    io << "</span>"
    io << "
"
    io << "          "
    io << "</span>"
    io << "
"
    io << "        "
    io << "</span>"
    io << "
"
    io << "        "
    io << "<span"
    io << " class"
    io << "=\""
    ("alongside").to_s io
    io << "\""
    unless Process.pid == false
      io << " pid"
      unless Process.pid == true
        io << "=\""
        io << (Process.pid).to_s.gsub(/"/, "&quot;")
        io << "\""
      end
    end
    io << ">"
    io << "
"
    io << "          "
    io << "<custom-tag"
    io << " id=\"with-id\""
    unless "#{Process.pid}" == false
      io << " pid"
      unless "#{Process.pid}" == true
        io << "=\""
        io << ("#{Process.pid}").to_s.gsub(/"/, "&quot;")
        io << "\""
      end
    end
    io << ">"
    ["ah", "oh"].each do |s|
      io << "
"
      io << "            "
      io << "<span"
      io << ">"
      io << HTML.escape((s).to_s).to_s
      io << "</span>"
    end
    io << "
"
    io << "          "
    io << "</custom-tag>"
    io << "
"
    io << "        "
    io << "</span>"
    io << "
"
    io << "      "
    io << "</div>"
    io << "
"
    io << "    "
    io << "</span>"
    io << "
"
    io << "    "
    io << "<div"
    io << " id=\"amazing-div\""
    unless "hello" == false
      io << " some-attr"
      unless "hello" == true
        io << "=\""
        io << ("hello").to_s.gsub(/"/, "&quot;")
        io << "\""
      end
    end
    io << ">"
    io << "</div>"
    io << "
"
    io << "    "
    io << "<!--"
    io << "This is a visible comment"
    io << "-->"
    io << "
"
    io << "    "
    io << "<script"
    io << ">"
    io << ("var num1 = 8*4;").to_s
    io << "</script>"
    io << "
"
    io << "    "
    io << "<script"
    io << ">"
    io << "
"
    io << "      "
    io << ("var num2 = 8*3;").to_s
    io << "
"
    io << "      "
    io << ("alert(\"8 * 3 + 8 * 4 = \" + (num1 + num2));").to_s
    io << "
    </script>
  </body>
</html>"
  end
end

# Benchmark.ips do |x|
#   x.report("old") { old }
#   x.report("new") { new }
# end
puts old.colorize.red
puts new.colorize.green
puts(old == new)
