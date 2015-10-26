require 'spec_helper'

describe Heapy do
  it 'has a version number' do
    expect(Heapy::VERSION).not_to be nil
  end

  it "drills down" do
    out = run("bin/heapy read #{ fixtures('00-heap.dump') } 36")
    expect(out).to match("377065  /Users/richardschneeman/Documents/projects/codetriage/app/views/layouts/application.html.slim:1")

    expect(out).to match("4  \"application\"")
    puts out
  end

  it 'analyzes' do
    out = run("bin/heapy read #{ fixtures('00-heap.dump') }")
    expect(out).to match("Generation: nil object count: 209189")
  end
end
