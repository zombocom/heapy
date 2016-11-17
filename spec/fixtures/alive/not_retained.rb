$LOAD_PATH.unshift(File.expand_path(File.join(__FILE__, "../../../../lib")))


require 'heapy'

Heapy::Alive.start_object_trace!(heap_file: ENV.fetch('HEAP_FILE'))

def run
  string = "string"
  Heapy::Alive.trace_without_retain(string)

  array  = []
  Heapy::Alive.trace_without_retain(array)

  hash   = {}
  Heapy::Alive.trace_without_retain(hash)

  return nil
end

run

alive_count = Heapy::Alive.traced_objects.select {|tracer| tracer.object_retained? }.length
# should return 0, no traced objects are returned

puts "Heapy output: #{alive_count}"
