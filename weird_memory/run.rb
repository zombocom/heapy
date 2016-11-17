arg = ARGV.shift

def run(file)
  cmd = "bundle exec ruby #{file}"
  puts "  $ #{ cmd }"
  puts "    " + `#{cmd}`
end

if arg.nil? || arg.downcase == "all"
  puts "== Running all directories (#{`ruby -v`.strip})"
  Dir.glob("weird_memory/**/*.rb").each do |file|
    next if file == __FILE__
    run(file)
  end
else
  puts "== Running examples in `#{arg}` directory (#{`ruby -v`.strip})"

  Dir.glob("weird_memory/#{arg}/**/*.rb").each do |file|
    run(file)
  end
end
