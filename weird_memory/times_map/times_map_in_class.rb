$LOAD_PATH.unshift(File.expand_path(File.join(__FILE__, "../../../lib")))

require 'heapy'

Heapy::Alive.start_object_trace!(heap_file: ENV.fetch('HEAP_FILE') { 'tmp/heap.json' })

class Runner
  def run
    array = 1.times.map {
      string = ""
      Heapy::Alive.trace_without_retain(string)
      string
    }
    array = nil
    return nil
  end
end

Runner.new.run

alive_count = Heapy::Alive.traced_objects.select {|tracer|
  tracer.object_retained?
}.length
# should return 0, no traced objects are returned

expected = 0
actual = alive_count
result = expected == actual ? "PASS" : "FAIL"
puts "#{result}: expected: #{expected}, actual: #{actual}"
