require 'bundler/gem_tasks'
require 'rubocop/rake_task'
require 'rake/testtask'
require 'rspec/core/rake_task'

# test task is not part of default task list,
# because it requires a node to test against
task default: %w(rubocop spec build)

RuboCop::RakeTask.new

RSpec::Core::RakeTask.new(:spec_yaml) do |t|
  t.pattern = 'spec/yaml_spec.rb'
end

task spec: [:spec_yaml]

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
