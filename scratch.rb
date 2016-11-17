


$LOAD_PATH.unshift(File.expand_path(File.join(__FILE__, "../lib")))

load File.expand_path(File.join(__FILE__, "../lib/heapy.rb"))


# class Foo
# end

# class Bar
# end

# class Baz
# end

# def run
#     foo = Foo.new
#     Heapy::Alive.trace_without_retain(foo)
#     foo.singleton_class
#     foo = nil

#     bar = Bar.new
#     Heapy::Alive.trace_without_retain(bar)
#     bar.singleton_class
#     bar = nil

#     baz = Baz.new
#     Heapy::Alive.trace_without_retain(baz)
#     baz.singleton_class
#     baz = nil
#   nil
# end

# Heapy::Alive.start_object_trace!

# run

# objects = Heapy::Alive.traced_objects.each do |obj|
#   puts "Address: #{obj.address} #{obj.tracked_to_s}\n  #{obj.raw_json_hash || "not found" }"
# end

Heapy::Alive.start_object_trace!

def run
  foo = ""
  Heapy::Alive.trace_without_retain(foo)
  b = []
  b << foo
  b
end

c = run

objects = Heapy::Alive.traced_objects.each do |tracer|
  puts "== Address: #{tracer.address} #{tracer.tracked_to_s}\n  #{tracer.raw_json_hash || "not found" }"
  # tracer.raw_json_hash["references"].each do |address|
  #   puts Heapy::Alive.address_to_object(address)
  # end
  Heapy::Alive.retained_by(tracer: tracer).each do |obj|
    puts obj.inspect
  end
end
