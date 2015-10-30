require 'objspace'

ObjectSpace.trace_object_allocations_start

array = []
10_000.times do |x|
  a = "#{x}_foo"
  array << a
end

# GC.start

file_name = "/tmp/#{Time.now.to_f}-heap.dump"
ObjectSpace.dump_all(output: File.open(file_name, 'w'))

puts "bin/heapy read #{file_name}"
