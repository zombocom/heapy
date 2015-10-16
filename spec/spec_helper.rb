$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'heapy'

require 'pathname'
    require "open3"


def fixtures(name)
  Pathname.new(File.expand_path("../fixtures", __FILE__)).join(name)
end


def run(cmd)
  out = ""
  Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
    err = stderr.read
    raise err unless err.empty?
    out = stdout.read
  end
  out
end