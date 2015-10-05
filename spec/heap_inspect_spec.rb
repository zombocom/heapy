require 'spec_helper'

describe Heapy do
  it 'has a version number' do
    expect(Heapy::VERSION).not_to be nil
  end

  it "drills down" do
    out = run("bin/heapy read #{ fixtures('00-heap.dump') } 36")
    expect(out).to match("Memory: 377065, Count: 1")
  end

  it 'analyzes' do
    out = run("bin/heapy read #{ fixtures('00-heap.dump') }")
    expect(out).to match("Generation:  0 object count: 209189")
  end
end
