require 'bundler/gem_tasks'
require 'rubocop/rake_task'
require 'rake/testtask'

# test task is not part of default task list,
# because it requires a node to test against
task default: %w(rubocop build)

RuboCop::RakeTask.new

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
