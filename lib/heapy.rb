require 'json'
require 'thor'

require "heapy/version"

module Heapy

  class CLI < Thor
    desc "read <file> <generation> --lines <number_of_lines>", "Read heap dump file"
    option :lines, required: false, :type => :numeric

     def read(file_name, generation = nil)
       if generation
         Analyzer.new(file_name).drill_down(generation, options[:lines] || 50)
       else
         Analyzer.new(file_name).analyze
       end
     end

     def help(*args)
       puts <<-HELP
Heapy helps you analyze heap dumps.

To get a heap dump do this:

   require 'objspace'
   ObjectSpace.trace_object_allocations_start

   # Your code here

   p ObjectSpace.dump_all

This will print the file name of your heap dump.

HELP

       super
     end
  end

end

require 'heapy/analyzer'
