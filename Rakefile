require 'bundler/gem_tasks'
require 'rubocop/rake_task'
require 'rake/testtask'
require 'rspec/core/rake_task'

# test task is not part of default task list,
# because it requires a node to test against
task default: %w(rubocop spec build)

RuboCop::RakeTask.new

# Because each of the below specs requires a clean Ruby environment,
# they need to be run individually instead of as a single RSpec task.
RSpec::Core::RakeTask.new(:spec_no_clients) do |t|
  t.pattern = 'spec/no_clients_spec.rb'
end
RSpec::Core::RakeTask.new(:spec_nxapi_only) do |t|
  t.pattern = 'spec/nxapi_only_spec.rb'
end
RSpec::Core::RakeTask.new(:spec_grpc_only) do |t|
  t.pattern = 'spec/grpc_only_spec.rb'
end
RSpec::Core::RakeTask.new(:spec_all_clients) do |t|
  t.pattern = 'spec/all_clients_spec.rb'
end
RSpec::Core::RakeTask.new(:spec_yaml) do |t|
  t.pattern = 'spec/yaml_spec.rb'
end
RSpec::Core::RakeTask.new(:spec_whitespace) do |t|
  t.pattern = 'spec/whitespace_spec.rb'
end

task spec: [:spec_no_clients,
            :spec_nxapi_only,
            :spec_grpc_only,
            :spec_all_clients,
            :spec_yaml,
            :spec_whitespace,
           ]

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
