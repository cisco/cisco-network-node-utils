require 'bundler/gem_tasks'
require 'rubocop/rake_task'
require 'rake/testtask'
require 'rspec/core/rake_task'

# test task is not part of default task list,
# because it requires a node to test against
task default: %w(rubocop spec build)

RuboCop::RakeTask.new

RSpec::Core::RakeTask.new(:spec_common) do |t|
  t.pattern = 'spec/*_spec.rb'
  t.rspec_opts = '--format documentation'
  t.verbose = false
end
spec_tasks = [:spec_common]

# Because each of the below specs requires a clean Ruby environment,
# they need to be run individually instead of as a single RSpec task.
Dir.glob('spec/isolate/*_spec.rb').each do |f|
  task = File.basename(f, '.rb').to_sym
  RSpec::Core::RakeTask.new(task) do |t|
    t.pattern = f
    t.rspec_opts = '--format documentation'
    t.verbose = false
  end
  spec_tasks << task
end

task spec: spec_tasks

task :build do
  system 'gem build cisco_node_utils.gemspec'
end

Rake::TestTask.new do |t|
  t.libs << 'lib'
  t.libs << 'tests'
  t.pattern = 'tests/test_*.rb'
  t.warning = true
  t.verbose = true
  t.options = '-v'
end
