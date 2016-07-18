require "bundler/gem_tasks"

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec)
task :default => :spec
task :default => :spec

if RUBY_VERSION >= "1.9"
  require "rubocop/rake_task"
  RuboCop::RakeTask.new(:rubocop)
  task :default => :rubocop
end
