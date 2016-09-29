Feature: Use Heapy to summarise the generations

  Scenario: Create Heap file and summarise by generation
    Given a file named "example.rb" with:
      """ruby
      require 'objspace'
      require 'tempfile'
      require 'heapy'

      #Start tracking your object allocations. Prior created objects
      #will have nil as their generation.

      ObjectSpace.trace_object_allocations_start

      #Example Code

      class HelloWorld

      end

      hello = HelloWorld.new

      output = Tempfile.new("json.txt")

      #Request a Garabage Collection
      GC.start

      #Dump the heap to a temporary file
      ObjectSpace.dump_all(output: output)
      output.close

      # Use  the Heapy Gem to Summarise
      Heapy::Analyzer.new(output).analyze
      """

     When I run `ruby example.rb`
     Then the exit status should be 0
     Then show me the results
     Then it should produce the following output:
       | Analyzing Heap                              |
       | ==============                              |
       | Generation: nil object count: \d*, mem:.*   |
       | Generation:  \d* object count: \d*, mem:.*  |
       |                                             |
       | Heap total                                  |
       | ==============                              |
       | Generations \(active\): \d*                 |
       | Count: \d*                                  |
       | Memory: .*                                  |
