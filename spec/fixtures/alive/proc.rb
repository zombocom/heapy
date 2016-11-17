$LOAD_PATH.unshift(File.expand_path(File.join(__FILE__, "../../../../lib")))


require 'heapy'

Heapy::Alive.start_object_trace!(heap_file: ENV.fetch('HEAP_FILE'))

class Foo
end

def run
  thing = 3.times.map {
    foo = Foo.new
    Heapy::Alive.trace_without_retain(foo)
    foo
  }
  nil
end

run

alive_count = Heapy::Alive.traced_objects.select {|tracer|
  puts tracer.inspect
  tracer.object_retained?
}.length
# should return 0, no traced objects are returned

puts "Heapy output: #{alive_count}"
