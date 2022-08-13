require 'spec_helper'

describe Heapy do
  it 'has a version number' do
    expect(Heapy::VERSION).not_to be nil
  end

  describe "heap diffs" do
    it "diffs 2 heaps" do
      out = run("bin/heapy diff #{fixtures('dumps/diff/my_dump_1.json')} #{fixtures('dumps/diff/my_dump_2.json')}")
      expect(out).to match("Allocated STRING 9991 objects")
    end

    it "diffs 3 heaps" do
      out = run("bin/heapy diff #{fixtures('dumps/diff/my_dump_1.json')} #{fixtures('dumps/diff/my_dump_2.json')} #{fixtures('dumps/diff/my_dump_3.json')}")

      expect(out).to match("Retained STRING 9991 objects")
    end

    it "outputs the diff" do
      Dir.mktmpdir do |tmp_dir|
        file = "#{tmp_dir}/output.dump"
        run("bin/heapy diff #{fixtures('dumps/diff/my_dump_1.json')} #{fixtures('dumps/diff/my_dump_2.json')} --output_diff=#{file}")

        expect(`cat #{file} | wc -l`).to match("10006")
      end
    end
  end

  it "drills down all" do
    out = run("bin/heapy read #{ fixtures('dumps/00-heap.dump') } all")
    # memory count
    expect(out).to match("4325616  /Users/richardschneeman/.gem/ruby/2.2.3/gems/activesupport-4.2.3/lib/active_support/core_ext/marshal.rb:6")

    # class counts
    expect(out).to match("19046  String")
  end

  it "drills down" do
    out = run("bin/heapy read #{ fixtures('dumps/00-heap.dump') } 36")

    # memory count
    expect(out).to match("377065  /Users/richardschneeman/Documents/projects/codetriage/app/views/layouts/application.html.slim:1")

    # string counts
    expect(out).to match("4  \"application\"")

    # class counts
    expect(out).to match("545  String")

    # ref counts
    expect(out).to match("1672  /Users/richardschneeman/.gem/ruby/2.2.3/gems/activerecord-4.2.3/lib/active_record/attribute.rb:5")
  end

  context 'with no generation specified' do
    let(:cmd) { "bin/heapy read #{ fixtures('dumps/00-heap.dump') }" }
    it 'analyzes' do
      out = run(cmd)
      expect(out).to match("Generation: nil object count: 209189")
    end

    it "summarizes" do
      out = run(cmd)
      expect(out).to include("Heap total")
      expect(out).to include("Generations (active): 5")
      expect(out).to include("Count: 278443")
      expect(out).to include("Memory: 8004.6 kb")
    end
  end
end
