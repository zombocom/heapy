require 'spec_helper'

describe Heapy do
  it 'has a version number' do
    expect(Heapy::VERSION).not_to be nil
  end

  it "drills down all" do
    out = run("bin/heapy read #{ fixtures('00-heap.dump') } all")
    expect(out).to match("4325616  /Users/richardschneeman/.gem/ruby/2.2.3/gems/activesupport-4.2.3/lib/active_support/core_ext/marshal.rb:6")
  end

  it "drills down" do
    out = run("bin/heapy read #{ fixtures('00-heap.dump') } 36")

    # memory count
    expect(out).to match("377065  /Users/richardschneeman/Documents/projects/codetriage/app/views/layouts/application.html.slim:1")

    # string counts
    expect(out).to match("4  \"application\"")

    # ref counts
    expect(out).to match("1672  /Users/richardschneeman/.gem/ruby/2.2.3/gems/activerecord-4.2.3/lib/active_record/attribute.rb:5")
  end

  it 'analyzes' do
    out = run("bin/heapy read #{ fixtures('00-heap.dump') }")
    expect(out).to match("Generation: nil object count: 209189")
  end
end
