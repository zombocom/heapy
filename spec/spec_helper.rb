$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'heap_inspect'

require 'pathname'
    require "open3"


def fixtures(name)
  Pathname.new(File.expand_path("../fixtures", __FILE__)).join(name)
end


def run(cmd)
  out = ""
  Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
    out = stdout.read
  end
  out
end