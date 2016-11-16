module Heapy
  module Alive
    @mutex = Mutex.new
    @retain_hash = {}
    @heap_file   = nil
    @started     = false

    def self.start_object_trace!(heap_file: "./tmp/heap.json")
      @mutex.synchronize do
        @started   ||= true && ObjectSpace.trace_object_allocations_start
        @heap_file ||= heap_file
      end
    end

    def self.trace_without_retain(object)
      tracker = ObjectTracker.new(object_id: object.object_id, to_s: object.inspect)
      @mutex.synchronize do
        @retain_hash[tracker.address] = tracker
      end
    end

    def retained_by(tracer: nil, address: nil)
      address = tracer.address if tracer
      tracer  = @retain_hash[address]

      raise "must provide tracer or address" if address.nil?
      raise "not a valid address #{address}" if tracer.nil?

      Analyzer.new(@heap_file).read do |json_hash|
        json_hash["references"].each do |address|
          retainer = ObjectTracker.new(address: json_hash["address"], to_s: "object not traced".freeze)
          retainer.raw_json_hash = json_hash

          tracer.add_ref(retainer)
        end
      end

      tracer.retained_by
    end

    def self.traced_objects
      raise "You aren't tracing anything call Heapy::Alive.trace_without_retain first" if @retain_hash.empty?
      GC.start
      ObjectSpace.dump_all(output: File.open(@heap_file,'w'))

      Analyzer.new(@heap_file).read do |json_hash|
        address = json_hash["address"]
        if tracer = @retain_hash[address]
          tracer.raw_json_hash = json_hash
        end
      end
      @retain_hash.values
    end

    class ObjectTracker
      attr_reader :address, :tracked_to_s

      def initialize(object_id: nil, address: nil, to_s: )
        if object_id
          @address = "0x%08x" % (object_id * 2)
        else
          @address = address
        end

        raise "must provide address: #{@address.inspect}" if @address.nil?

        @tracked_to_s      = to_s.dup
        @referenced_by     = []
      end

      def add_ref(ref)
        @referenced_by << ref
      end

      def references
        @referenced_by
      end

      attr_accessor :raw_json_hash
    end
  end
end