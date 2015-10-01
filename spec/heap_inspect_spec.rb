require 'spec_helper'

describe HeapInspect do
  it 'has a version number' do
    expect(HeapInspect::VERSION).not_to be nil
  end

  it "drills down" do
    out = run("bin/heap_inspect read #{ fixtures('00-heap.dump') } 36")
    expect(out).to match("Memory: 377065, Count: 1")
  end

  it 'analyzes' do
    out = run("bin/heap_inspect read #{ fixtures('00-heap.dump') }")
    expect(out).to match("Generation:  0 object count: 209189")
  end
end
