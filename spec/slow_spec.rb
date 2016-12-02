describe Heapy::Alive do
  it "passes all the edge cases" do
    Tempfile.open('heap') do |f|
      out = run("env HEAP_FILE=#{f.path} ruby #{ fixtures('../../weird_memory/run.rb') }")
      expect(out).to_not match("FAIL")
    end
  end
end
