require "bundler/gem_tasks"
require "rspec/core/rake_task"
require 'cucumber/rake/task'

RSpec::Core::RakeTask.new(:spec)
Cucumber::Rake::Task.new(:cucumber)

task :default => [:spec, :cucumber]
task :test    => :spec

desc "console "
task :console do
  require 'irb'
  require 'heapy'
  ARGV.clear
  IRB.start
end
