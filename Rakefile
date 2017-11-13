require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  warn e.message
  warn 'Run `bundle install` to install missing gems'
  exit e.status_code
end
require 'rake'

# LINT
require 'rubocop/rake_task'
RuboCop::RakeTask.new(:lint) do |task|
  task.patterns = [
    'lib/**/*.rb',
    # Excluding ./spec/site
    'spec/*.rb',
    'spec/jekyll/**/*.rb'
  ]
  task.options = ['--display-cop-names']
end

# TEST
require 'rspec/core'
require 'rspec/core/rake_task'
desc 'Run tests (with simple progress)'
RSpec::Core::RakeTask.new(:test) do |task|
  task.rspec_opts = '--color --format progress'
  task.pattern = [
    'spec/*.rb',
    'spec/jekyll/**/*.rb'
  ]
end
desc 'Run tests (with full details)'
RSpec::Core::RakeTask.new(:test_details) do |task|
  task.rspec_opts = '--color --format documentation'
  task.pattern = [
    'spec/*.rb',
    'spec/jekyll/**/*.rb'
  ]
end
desc 'Run tests in all Ruby versions (with full details)'
task :test_all_ruby_versions do
  sh './scripts/test_all_ruby_versions'
end

# WATCH
desc 'Watch for changes in files and reload tests'
task :watch do
  # We specifically watch for ./lib and ./spec and not the whole dir because:
  # 1. It's the only directories we are interested in
  # 2. Listening to the whole parent dir might throw Guard errors if we have
  #    symlink
  sh 'bundle exec guard --clear --watchdir lib spec'
end

task default: :test
