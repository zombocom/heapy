$LOAD_PATH.unshift(File.expand_path(File.join(__FILE__, "../../../../lib")))


require 'heapy'

Heapy::Alive.start_object_trace!(heap_file: ENV.fetch('HEAP_FILE'))

def run
  string = "string".dup
  Heapy::Alive.trace_without_retain(string)

  array  = [].dup
  Heapy::Alive.trace_without_retain(array)

  hash   = {}.dup
  Heapy::Alive.trace_without_retain(hash)

  return [string, array, hash]
end

puts "Running"

out = run

alive_count = Heapy::Alive.traced_objects.select {|tracer| tracer.object_retained? }.length
# should return 0, no traced objects are returned

puts "Heapy output: #{alive_count}"

Heapy::Alive.traced_objects(retained_by: true).each do |tracer|
  puts "Traced: #{tracer.raw_json_hash}"
  tracer.retained_by.each do |retainer|
    # Should output array since it is retaining the thing
    puts "  Retained by: #{retainer.raw_json_hash}"
  end
end