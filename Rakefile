require 'bundler/gem_tasks'
require 'rubocop/rake_task'

task :default => %w(rubocop build)

RuboCop::RakeTask.new

task :build do
  system "gem build cisco_node_utils.gemspec"
end
