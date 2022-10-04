require 'json'
require 'readline'
require 'set'

module Heapy

  # Follows references to given object addresses and prints
  # them as a reference stack.
  # Since multiple reference stacks are possible, it will preferably
  # try to print a stack that leads to a root node, since reference chains
  # leading to a root node will make an object non-collectible by GC.
  #
  # In case no chain to a root node can be found one possible stack is printed
  # as a fallback.
  class ReferenceExplorer
    def initialize(filename)
      @objects = {}
      @reverse_references = {}
      @virtual_root_address = 0
      File.open(filename) do |f|
        f.each.with_index do |line, i|
          o = JSON.parse(line)
          addr = add_object(o)
          add_reverse_references(o, addr)
          add_class_references(o, addr)
        end
      end
    end

    def drill_down_list(addresses)
      addresses.each { |addr| drill_down(addr) }
    end

    def drill_down_interactive
      while buf = Readline.readline("Enter address > ", true)
        drill_down(buf)
      end
    end

    def drill_down(addr_string)
      addr = addr_string.to_i(16)
      puts

      chain = find_root_chain(addr)
      unless chain
        puts 'Could not find a reference chain leading to a root node. Searching for a non-specific chain now.'
        puts
        chain = find_any_chain(addr)
      end

      puts '## Reference chain'
      chain.each do |ref|
        puts format_object(ref)
      end

      puts
      puts "## All references to #{addr_string}"
      refs = @reverse_references[addr] || []
      refs.each do |ref|
        puts " * #{format_object(ref)}"
      end

      puts
    end

    def inspect
      "<ReferenceExplorer #{@objects.size} objects; #{@reverse_references.size} back-refs>"
    end

    private

    def add_object(o)
      addr = o['address']&.to_i(16)
      if !addr && o['type'] == 'ROOT'
        addr = @virtual_root_address
        o['name'] ||= o['root']
        @virtual_root_address += 1
      end

      return unless addr

      simple_object = o.slice('type', 'file', 'name', 'class', 'length', 'imemo_type')
      simple_object['class'] = simple_object['class'].to_i(16) if simple_object.key?('class')
      simple_object['file'] = o['file'] + ":#{o['line']}" if o.key?('file') && o.key?('line')

      @objects[addr] = simple_object

      addr
    end

    def add_reverse_references(o, addr)
      return unless o.key?('references')
      o.fetch('references').map { |r| r.to_i(16) }.each do |ref|
        (@reverse_references[ref] ||= []) << addr
      end
    end

    # An instance of a class keeps that class marked by the GC.
    # This is not directly indicated as a reference in a heap dump,
    # so we manually introduce the back-reference.
    def add_class_references(o, addr)
      return unless o.key?('class')
      return if o['type'] == 'IMEMO'

      class_addr = o.fetch('class').to_i(16)
      (@reverse_references[class_addr] ||= []) << addr
    end

    def find_root_chain(addr, known_addresses = Set.new)
      known_addresses << addr

      return [addr] if addr < @virtual_root_address # assumption: only root objects have smallest possible addresses

      references = @reverse_references[addr] || []

      references.reject { |a| known_addresses.include?(a) }.each do |ref|
        path = find_root_chain(ref, known_addresses)
        return [addr] + path if path
      end

      nil
    end

    def find_any_chain(addr, known_addresses = Set.new)
      known_addresses << addr

      references = @reverse_references[addr] || []

      next_ref = references.reject { |a| known_addresses.include?(a) }.first
      if next_ref
        [addr] + find_any_chain(next_ref, known_addresses)
      else
        []
      end
    end

    def format_path(path)
      return '' unless path

      path.split('/').reverse.take(4).reverse.join('/')
    end

    def format_object(addr)
      obj = @objects[addr]
      return "<Unknown 0x#{addr.to_s(16)}>" unless obj

      desc =  if obj['name']
                obj['name']
              elsif obj['type'] == 'OBJECT'
                @objects.dig(obj['class'], 'name')
              elsif obj['type'] == 'ARRAY'
                "#{obj['length']} items"
              elsif obj['type'] == 'IMEMO'
                obj['imemo_type']
              end
      desc = desc ? " #{desc}" : ''
      addr = addr ? " 0x#{addr.to_s(16).upcase}" : ''
      "<#{obj['type']}#{desc}#{addr}> (allocated at #{format_path obj['file']})"
    end
  end
end
