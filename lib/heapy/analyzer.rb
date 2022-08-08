module Heapy

  # Used for inspecting contents of a heap dump
  #
  # To glance all contents at a glance run:
  #
  #   Analyzer.new(file_name).analyze
  #
  # To inspect contents of a specific generation run:
  #
  #   Analyzer.new(file_name).drill_down(generation, Float::INFINITY)
  class Analyzer
    def initialize(filename)
      @filename = filename
    end

    def read
      File.open(@filename) do |f|
        f.each_line do |line|
          begin
            parsed = JSON.parse(line)
            yield parsed
          rescue JSON::ParserError
            puts "Could not parse #{line}"
          end
        end
      end
    end

    def drill_down(generation_to_inspect, max_items_to_display)
      puts ""
      puts "Analyzing Heap (Generation: #{generation_to_inspect})"
      puts "-------------------------------"
      puts ""

      generation_to_inspect = Integer(generation_to_inspect) unless generation_to_inspect == "all"

      memsize_hash    = counters_hash
      count_hash      = counters_hash
      string_count    = Hash.new { |h, k| h[k] = counters_hash }

      reference_hash  = counters_hash
      class_names = {}
      class_address_references = counters_hash

      read do |parsed|
        if parsed["type"] == "CLASS".freeze
          class_names[parsed["address"]] = parsed["name"] if parsed["name"]
        end

        generation = parsed["generation"] || 0
        if generation_to_inspect == "all".freeze || generation == generation_to_inspect
          next unless parsed["file"]

          key = "#{ parsed["file"] }:#{ parsed["line"] }"
          memsize_hash[key] += parsed["memsize"] || 0
          count_hash[key]   += 1

          if parsed["type"] == "STRING".freeze
            string_count[parsed["value"]][key] += 1 if parsed["value"]
          end

          if parsed["references"]
            reference_hash[key] += parsed["references"].length
          end

          if parsed["class"]
            class_address_references[parsed["class"]] += 1
          end
        end
      end

      raise "not a valid Generation: #{generation_to_inspect.inspect}" if memsize_hash.empty?

      total_memsize = memsize_hash.inject(0){|count, (k, v)| count += v}

      # /Users/richardschneeman/Documents/projects/codetriage/app/views/layouts/application.html.slim:1"=>[{"address"=>"0x7f8a4fbf2328", "type"=>"STRING", "class"=>"0x7f8a4d5dec68", "bytesize"=>223051, "capacity"=>376832, "encoding"=>"UTF-8", "file"=>"/Users/richardschneeman/Documents/projects/codetriage/app/views/layouts/application.html.slim", "line"=>1, "method"=>"new", "generation"=>36, "memsize"=>377065, "flags"=>{"wb_protected"=>true, "old"=>true, "long_lived"=>true, "marked"=>true}}]}
      puts "allocated by memory (#{total_memsize}) (in bytes)"
      puts "=============================="
      memsize_hash = top_n(memsize_hash, max_items_to_display)
      longest      = memsize_hash.first[1].to_s.length
      memsize_hash.each do |file_line, memsize|
        puts "  #{memsize.to_s.rjust(longest)}  #{file_line}"
      end

      total_count = count_hash.inject(0){|count, (k, v)| count += v}

      puts ""
      puts "object count (#{total_count})"
      puts "=============================="
      count_hash = top_n(count_hash, max_items_to_display)
      longest      = count_hash.first[1].to_s.length
      count_hash.each do |file_line, memsize|
        puts "  #{memsize.to_s.rjust(longest)}  #{file_line}"
      end

      puts ""
      puts "object counts by class"
      puts "=============================="
      class_counts_hash = class_address_references.each_with_object({}) do |(address, count), hash|
        hash[class_names[address]] = count if class_names.key?(address)
      end
      class_counts_hash = top_n(class_counts_hash, max_items_to_display)
      longest = class_counts_hash.first[1].to_s.length
      class_counts_hash.each do |class_name, count|
        puts "  #{count.to_s.rjust(longest)}  #{class_name}"
      end

      puts ""
      puts "High Ref Counts"
      puts "=============================="
      puts ""

      reference_hash = top_n(reference_hash, max_items_to_display)
      longest      = count_hash.first[1].to_s.length

      reference_hash.each do |file_line, count|
        puts "  #{count.to_s.rjust(longest)}  #{file_line}"
      end

      if !string_count.empty?
        puts ""
        puts "Duplicate strings"
        puts "=============================="
        puts ""

        value_count = {}

        string_count.each do |string, location_count_hash|
          value_count[string] = location_count_hash.values.inject(&:+)
        end

        value_count = top_n(value_count, max_items_to_display)
        longest     = value_count.first[1].to_s.length

        value_count.each do |string, c1|

          puts " #{c1.to_s.rjust(longest)}  #{string.inspect}"
          string_count[string].sort {|(k1, v1), (k2, v2)| v2 <=> v1 }.each do |file_line, c2|
           puts " #{c2.to_s.rjust(longest)}  #{file_line}"
         end
         puts ""
        end
      end

    end

    def analyze
      puts ""
      puts "Analyzing Heap"
      puts "=============="
      default_key = "nil".freeze

      # generation number is key, value is count
      data = counters_hash
      mem = counters_hash
      total_count = 0
      total_mem = 0

      read do |parsed|
        data[parsed["generation"] || 0] += 1
        mem[parsed["generation"] || 0] += parsed["memsize"] || 0
      end

      data = data.sort {|(k1,v1), (k2,v2)| k1 <=> k2 }
      max_length = [data.last[0].to_s.length, default_key.length].max
      data.each do |generation, count|
        generation = default_key if generation == 0
        total_count += count
        total_mem += mem[generation]
        puts "Generation: #{ generation.to_s.rjust(max_length) } object count: #{ count }, mem: #{(mem[generation].to_f / 1024).round(1)} kb"
      end

      puts ""
      puts "Heap total"
      puts "=============="
      puts "Generations (active): #{data.length}"
      puts "Count: #{total_count}"
      puts "Memory: #{(total_mem.to_f / 1024).round(1)} kb"
    end

    private

    def counters_hash
      Hash.new { |h, k| h[k] = 0 }
    end

    def top_n(hash, n)
      hash.sort {|(k1, v1), (k2, v2)| v2 <=> v1 }.first(n)
    end
  end
end
