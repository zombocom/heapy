Feature: Use Heapy to dig into a Generation

  Scenario: Generate a heap dump and drill into the details
    Given a file named "example.rb" with:
      """ruby
      require 'objspace'
      require 'tempfile'
      require 'heapy'

      ObjectSpace.trace_object_allocations_start

      # Example Code
      some_reference =[]
      1_000.times do |x|
      some_reference <<  "This is an #{x.odd? ? 'odd': 'even'} item"
      end

      output = Tempfile.new("json.txt")

      GC.start

      ObjectSpace.dump_all(output: output)

      #Use Heap to do detailed analysis
      Heapy::Analyzer.new(output).drill_down("all")
      output.close
      """

     When I run `ruby example.rb`
     Then the exit status should be 0
     Then it should produce the following output:
       | Analyzing Heap \(Generation: all\)        |
       | -------------------------------           |
       |                                           |
       | allocated by memory \(\d*\) \(in bytes\)  |
       | ==============================            |
       |   \d*  example.rb:10                      |
       |   \d*  example.rb:8                       |
       |                                           |
       | object count \(\d*\)                      |
       | ==============================            |
       |   1000  example.rb:10                     |
       |      4  example.rb:17                     |
       |                                           |
       | High Ref Counts                           |
       | ==============================            |
       |                                           |
       |   1000  example.rb:8                      |
       |                                           |
       | Duplicate strings                         |
       | ==============================            |
       |                                           |
       |  500  "This is an odd item"               |
       |  500  example.rb:10                       |
       |                                           |
       |  500  "This is an even item"              |
       |  500  example.rb:10                       |
