require "slang"

if ARGV[0]? == "--extract"
  puts Slang.extract_strings_from_file(ARGV[1])
else
  puts Slang.process_file(ARGV[0], ARGV[1], translate: ARGV.includes?("--translate"))
end
