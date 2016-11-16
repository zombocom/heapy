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
    Generation: nil object count: 209191
    Generation:  14 object count: 407
    Generation:  15 object count: 638
    Generation:  16 object count: 748
    Generation:  17 object count: 1023
    Generation:  18 object count: 805

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
end

require 'heapy/analyzer'
require 'heapy/alive'

