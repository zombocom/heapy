arg = ARGV.shift

@fail_count = 0

require 'fileutils'
FileUtils.mkdir_p("tmp")

def run(file, fail_count: @fail_count)
  cmd = "bundle exec ruby #{file}"
  puts "  $ #{ cmd }"
  result = `#{cmd}`
  @fail_count += 1 if result.match(/FAIL/)
  puts "    " + result
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

puts
puts "Total failed: #{@fail_count}"
