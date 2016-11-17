require 'spec_helper'

describe Heapy::Alive do

  it "determines objects are NOT retained" do
    Tempfile.open('heap') do |f|
      out = run("env HEAP_FILE=#{f.path} ruby #{ fixtures('alive/not_retained.rb') }")
      expect(out).to match("Heapy output: 0")
    end
  end

  it "determines objects ARE retained" do
    Tempfile.open('heap') do |f|
      out = run("env HEAP_FILE=#{f.path} ruby #{ fixtures('alive/retained.rb') }")
      expect(out).to match("Heapy output: 3")
    end
  end

  it "finds parents of an object" do
    Tempfile.open('heap') do |f|
      out = run("env HEAP_FILE=#{f.path} ruby #{ fixtures('alive/retained.rb') }")
      array_in_heap = %Q{"type"=>"ARRAY"}
      expect(out).to match(array_in_heap)

      # Pull out only lines that show "Retained by"
      retained_lines = out.each_line.map.select {|line| line.match(/Retained by/)}.join("\n")

      # All three items traced should be retained by the same array
      array_count = retained_lines.scan(array_in_heap).count
      expect(array_count).to eq(3), "Expected output: #{out} to contain 3 retaining arrays, but was #{array_count}"
    end
  end
end
