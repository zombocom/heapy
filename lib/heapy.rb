require 'json'

require "heapy/version"

module Heapy

  class CLI
    def initialize(argv)
      @cmd    = argv.shift
      @file   = argv.shift
      @number = argv.shift
      @args   = argv
    end

    def help
      puts <<-HALP
$ heapy read <file|command> <number>

When run with only a file, it will output the generation and count pairs:

  $ heapy read tmp/2015-09-30-heap.dump
    Generation:  0 object count: 209191
    Generation: 14 object count: 407
    Generation: 15 object count: 638
    Generation: 16 object count: 748
    Generation: 17 object count: 1023
    Generation: 18 object count: 805

When run with a file and a number it will output detailed information for that
generation:

  $ heapy read tmp/2015-09-30-heap.dump 17

    Analyzing Heap (Generation: 17)
    -------------------------------

allocated by memory (44061517) (in bytes)
==============================
  39908512  /app/vendor/ruby-2.2.3/lib/ruby/2.2.0/timeout.rb:79
   1284993  /app/vendor/ruby-2.2.3/lib/ruby/2.2.0/openssl/buffering.rb:182
    201068  /app/vendor/bundle/ruby/2.2.0/gems/json-1.8.3/lib/json/common.rb:223
    189272  /app/vendor/bundle/ruby/2.2.0/gems/newrelic_rpm-3.13.2.302/lib/new_relic/agent/stats_engine/stats_hash.rb:39
    172531  /app/vendor/ruby-2.2.3/lib/ruby/2.2.0/net/http/header.rb:172
     92200  /app/vendor/bundle/ruby/2.2.0/gems/activesupport-4.2.3/lib/active_support/core_ext/numeric/conversions.rb:131
HALP
    end

    def run

      case @cmd
      when "--help"
        help
      when nil
        help
      when "read"
        if @number
          Analyzer.new(@file).drill_down(@number)
        else
          Analyzer.new(@file).analyze
        end
      else
        help
      end
    end
  end

  class Analyzer
    def initialize(filename)
      @filename = filename
    end

    def drill_down(generation)
      puts ""
      puts "Analyzing Heap (Generation: #{generation})"
      puts "-------------------------------"
      puts ""

      generation = Integer(generation)

      #
      memsize_hash = Hash.new { |h, k| h[k] = 0 }
      count_hash   = Hash.new { |h, k| h[k] = 0 }
      File.open(@filename) do |f|
        f.each_line do |line|
          begin
            parsed = JSON.parse(line)
            if parsed["generation"] == generation
              key = "#{ parsed["file"] }:#{ parsed["line"] }"
              memsize_hash[key] += parsed["memsize"]
              count_hash[key]   += 1
            end
          rescue JSON::ParserError
            puts "Could not parse #{line}"
          end
        end
      end

      total_memsize = memsize_hash.inject(0){|count, (k, v)| count += v}

      # /Users/richardschneeman/Documents/projects/codetriage/app/views/layouts/application.html.slim:1"=>[{"address"=>"0x7f8a4fbf2328", "type"=>"STRING", "class"=>"0x7f8a4d5dec68", "bytesize"=>223051, "capacity"=>376832, "encoding"=>"UTF-8", "file"=>"/Users/richardschneeman/Documents/projects/codetriage/app/views/layouts/application.html.slim", "line"=>1, "method"=>"new", "generation"=>36, "memsize"=>377065, "flags"=>{"wb_protected"=>true, "old"=>true, "long_lived"=>true, "marked"=>true}}]}
      puts "allocated by memory (#{total_memsize}) (in bytes)"
      puts "=============================="
      memsize_hash = memsize_hash.sort {|(k1, v1), (k2, v2)| v2 <=> v1 }
      longest      = memsize_hash.first[1].to_s.length
      memsize_hash.each do |file_line, memsize|
        puts "  #{memsize.to_s.rjust(longest)}  #{file_line}"
      end

      total_count = count_hash.inject(0){|count, (k, v)| count += v}

      puts ""
      puts "object count (#{total_count})"
      puts "============"
      count_hash = count_hash.sort {|(k1, v1), (k2, v2)| v2 <=> v1 }
      longest      = count_hash.first[1].to_s.length
      count_hash.each do |file_line, memsize|
        puts "  #{memsize.to_s.rjust(longest)}  #{file_line}"
      end
    end

    def analyze
      puts ""
      puts "Analyzing Heap"
      puts "=============="

      # generation number is key, value is count
      data = Hash.new {|h, k| h[k] = 0 }

      File.open(@filename) do |f|
        f.each_line do |line|
          begin
            line = line.chomp
            json = JSON.parse(line)
            data[json["generation"]||0] += 1
          rescue JSON::ParserError
            puts "Could not parse #{line}"
          end
        end
      end

      data = data.sort
      max_length = data.last[0].to_s.length
      data.each do |generation, count|
        puts "Generation: #{ generation.to_s.rjust(max_length) } object count: #{ count }"
      end
    end
  end
end
