require 'objspace'
require 'stringio'

module Heapy

  # This is an experimental module and likely to change. Don't use in production.
  #
  # Use at your own risk. APIs are not stable.
  #
  # == What
  #
  # You can use it to trace objects to see if they are still "alive" in memory.
  # Unlike the heapy CLI this is meant to be used in live running code.
  #
  # This works by retaining an object's address in memory, then running GC
  # and taking a heap dump. If the object exists in the heap dump, it is retained.
  # Since we have the whole heap dump we can also do things like find what is retaining
  # your object preventing it from being collected.
  #
  # == Use It
  #
  # You need to first start tracing objects:
  #
  #   Heapy::Alive.start_object_trace!(heap_file: "./tmp/heap.json")
  #
  # Next in your code you want to specify the object ato trace
  #
  #   string = "hello world"
  #   Heapy::Alive.trace_without_retain(string)
  #
  # When the code is done executing you can get a reference to all "tracer"
  # objects by running:
  #
  #   Heapy::Alive.traced_objects.each do |tracer|
  #     puts tracer.raw_json_hash if tracer.object_retained?
  #   end
  #
  # A few helpful methods on `tracer` objects:
  #
  # - `raw_json_hash` returns the hash of the object from the heap dump.
  # - `object_retained?` returns truthy if the object was still present in the heap dump.
  # - `address` a string of the memory address of the object you're tracing.
  # - `tracked_to_s` a string that represents the object you're tracing (default
  #    is result of calling inspect on the method). You can pass in a custom representation
  #    when initializing the object. Can be useful for when `inspect` on the object you
  #    are tracing is too verbose.
  # - `id2ref` returns the original object being traced (if it is still in memory).
  # - `root?` returns false if the tracer isn't the root object.
  #
  # See `ObjectTracker` for more methods.
  #
  # If you want to see what retains an object, you can use `ObectTracker#retained_by`
  # method (caution this is extremely expensive and requires re-walking the whole heap dump:
  #
  #   Heapy::Alive.traced_objects.each do |tracer|
  #     if tracer.object_retained?
  #       puts "Traced: #{tracer.raw_json_hash}"
  #       tracer.retained_by.each do |retainer|
  #         puts "  Retained by: #{retainer.raw_json_hash}"
  #       end
  #     end
  #   end
  #
  # You can iterate up the whole retained tree by using the `retained_by` method on tracers
  # returned. But again it's expensive. If you have large heap dump or if you're tracing a bunch
  # of objects, continuously calling `retained_by` will take lots of time. We also don't
  # do any circular dependency detection so if you have two objects that depend on each other,
  # you may hit an infinite loop.
  #
  # If you know that you'll need the retained objects of the main objects you're tracing you can
  # save re-walking the heap the first N times by using the `retained_by` flag:
  #
  #   Heapy::Alive.traced_objects(retained_by: true) do |tracer|
  #     # ...
  #   end
  #
  # This will pre-fetch the first level of "parents" for each object you're tracing.
  #
  # Did I mention this is all experimental and may change?
  module Alive
    @mutex = Mutex.new
    @retain_hash = {}
    @heap_file   = nil
    @started     = false

    def self.address_to_object(address)
      obj_id = address.to_i(16) / 2
      ObjectSpace._id2ref(obj_id)
    rescue RangeError
      nil
    end

    def self.start_object_trace!(heap_file: "./tmp/heap.json")
      @mutex.synchronize do
        @started   ||= true && ObjectSpace.trace_object_allocations_start
        @heap_file ||= heap_file
      end
    end

    def self.trace_without_retain(object, to_s: nil)
      tracker = ObjectTracker.new(object_id: object.object_id, to_s: to_s || object.inspect)
      @mutex.synchronize do
        @retain_hash[tracker.address] = tracker
      end
    end

    def self.retained_by(tracer: nil, address: nil)
      target_address = address || tracer.address
      tracer         = tracer  || @retain_hash[address]

      raise "not a valid address #{target_address}" if target_address.nil?

      retainer_array = []
      Analyzer.new(@heap_file).read do |json_hash|
        retainers_from_json_hash(json_hash, target_address: target_address, retainer_array: retainer_array)
      end

      retainer_array
    end

    class << self
      private def retainers_from_json_hash(json_hash, retainer_array:, target_address:)
        references = json_hash["references"]
        return unless references

        references.each do |address|
          next unless address == target_address

          if json_hash["root"]
            retainer = RootTracker.new(json_hash)
          else
            address        = json_hash["address"]
            representation = self.address_to_object(address)&.inspect || "object not traced".freeze
            retainer = ObjectTracker.new(address: address, to_s: representation)
            retainer.raw_json_hash = json_hash
          end

          retainer_array << retainer
        end
      end
    end

  private
    @string_io = StringIO.new
    # GIANT BALL OF HACKS || THERE BE DRAGONS
    #
    # There is so much I don't understand on why I need to do the things
    # I'm doing in this method.
    #
    # Also see `living_dead` https://github.com/schneems/living_dead
    def self.gc_start
      # During debugging I found calling "puts" made some things
      # mysteriously work, I have no idea why. If you remove this line
      # then (more) tests fail. Maybe it has something to do with the way
      # GC interacts with IO? I seriously have no idea.
      #
      @string_io.puts "=="

      # Calling flush so we don't create a memory leak.
      # Funny enough maybe calling flush without `puts` also works?
      # IDK
      #
      @string_io.flush

      # Calling GC multiple times fixes a different class of things
      # Specifically the singleton_class.instance_eval tests.
      # It might also be related to calling GC in a block, but changing
      # to 1.times brings back failures.
      #
      # Calling 2 times results in eventual failure https://twitter.com/schneems/status/804369346910896128
      # Calling 5 times results in eventual failure https://twitter.com/schneems/status/804382968307445760
      # Trying 10 times
      #
      10.times { GC.start }
    end
  public

    def self.traced_objects(retained_by: false)
      raise "You aren't tracing anything call Heapy::Alive.trace_without_retain first" if @retain_hash.empty?
      self.gc_start

      ObjectSpace.dump_all(output: File.open(@heap_file,'w'))

      retainer_address_array_hash = {}

      Analyzer.new(@heap_file).read do |json_hash|
        address = json_hash["address"]
        tracer = @retain_hash[address]
        next unless tracer
        tracer.raw_json_hash = json_hash

        if retained_by
          retainers_from_json_hash(json_hash, target_address: address, retainer_array: tracer.retained_by)
        end
      end
      @retain_hash.values
    end

    class RootTracker
      def initialize(json)
        @raw_json_hash = json
      end

      def references
        []
      end

      def id2ref
        raise "cannot turn root object into an object"
      end

      def root?
        true
      end

      def address
        raise "root does not have an address"
      end

      def object_retained?
        true
      end

      def tracked_to_s
        "ROOT"
      end
    end

    class ObjectTracker
      attr_reader :address, :tracked_to_s

      def initialize(object_id: nil, address: nil, to_s: )
        if object_id
          @address = "0x#{ (object_id << 1).to_s(16) }"
        else
          @address = address
        end

        raise "must provide address: #{@address.inspect}" if @address.nil?

        @tracked_to_s = to_s.dup
        @retained_by  = nil
      end

      def id2ref
        Heapy::Alive.address_to_object(address)
      end

      def root?
        false
      end

      def object_retained?
        raw_json_hash && raw_json_hash["address"]
      end

      def retainer_array
        @retained_by ||= []
        @retained_by
      end

      def retained_by
        @retained_by || Heapy::Alive.retained_by(tracer: self)
      end

      attr_accessor :raw_json_hash
    end
  end
end