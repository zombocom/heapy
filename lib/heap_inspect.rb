require 'json'

require "heap_inspect/version"

module HeapInspect

  class CLI
    def initialize(argv)
      @cmd    = argv.shift
      @file   = argv.shift
      @number = argv.shift
      @args   = argv
    end

    def help
      puts <<-HALP
$ heap_inspect read <file|command> <number>

When run with only a file, it will output the generation and count pairs:

  $ heap_inspect read tmp/2015-09-30-heap.dump
    Generation:  0 object count: 209191
    Generation: 14 object count: 407
    Generation: 15 object count: 638
    Generation: 16 object count: 748
    Generation: 17 object count: 1023
    Generation: 18 object count: 805

When run with a file and a number it will output detailed information for that
generation:

  $ heap_inspect read tmp/2015-09-30-heap.dump 17

    Analyzing Heap (Generation: 17)
    -------------------------------

    allocated by memory (in bytes)
    ==============================
    /Users/richardschneeman/Documents/projects/codetriage/app/views/layouts/application.html.slim:1 (Memory: 377065, Count: 1 )
    /Users/richardschneeman/.gem/ruby/2.2.3/gems/actionview-4.2.3/lib/action_view/template.rb:296 (Memory: 35814, Count: 67 )
    /Users/richardschneeman/.gem/ruby/2.2.3/gems/activerecord-4.2.3/lib/active_record/attribute.rb:5 (Memory: 30672, Count: 426 )

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
      data = []
      File.open(@filename) do |f|
        f.each_line do |line|
          parsed = JSON.parse(line)
          data << parsed if parsed["generation"] == generation
        end
      end


      # /Users/richardschneeman/Documents/projects/codetriage/app/views/layouts/application.html.slim:1"=>[{"address"=>"0x7f8a4fbf2328", "type"=>"STRING", "class"=>"0x7f8a4d5dec68", "bytesize"=>223051, "capacity"=>376832, "encoding"=>"UTF-8", "file"=>"/Users/richardschneeman/Documents/projects/codetriage/app/views/layouts/application.html.slim", "line"=>1, "method"=>"new", "generation"=>36, "memsize"=>377065, "flags"=>{"wb_protected"=>true, "old"=>true, "long_lived"=>true, "marked"=>true}}]}

      memsize_hash = {}
      data.group_by { |row| "#{row["file"]}:#{row["line"]}" }.
         each do |(k, v)|
           memsize_hash[k] = {
             count:   v.count,
             memsize:  v.inject(0) { |sum, obj| sum + Integer(obj["memsize"]) }
           }
         end


      puts "allocated by memory (in bytes)"
      puts "=============================="
      memsize_hash.sort {|(k1, v1), (k2, v2)| v2[:memsize] <=> v1[:memsize] }.
         each do |k,v|
           puts "#{k} (Memory: #{v[:memsize]}, Count: #{v[:count]} ) "
         end

      puts ""
      puts "object count"
      puts "============"
      memsize_hash.sort {|(k1, v1), (k2, v2)| v2[:count] <=> v1[:count] }.
         each do |k,v|
           puts "#{k} (Memory: #{v[:memsize]}, Count: #{v[:count]} ) "
         end
    end

    def analyze
      puts ""
      puts "Analyzing Heap"
      puts "=============="

      data = []
      File.open(@filename) do |f|
        f.each_line do |line|
          data << JSON.parse(line)
        end
      end

      data.group_by{ |row| row["generation"] }.
        sort { |a, b| a[0].to_i <=> b[0].to_i }.
        each do |k,v|
          puts "Generation: #{k || " 0"} object count: #{v.count}"
        end
    end
  end
end
