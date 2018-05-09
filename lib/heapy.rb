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
  end

end

require 'heapy/analyzer'
require 'heapy/alive'
