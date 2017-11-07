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

# TEST
require 'rspec/core'
require 'rspec/core/rake_task'
desc 'Run tests (with simple progress)'
RSpec::Core::RakeTask.new(:test) do |spec|
  spec.rspec_opts = '--color --format progress'
  spec.pattern = FileList['spec/credential_checker_spec.rb']
end
desc 'Run tests (with full details)'
RSpec::Core::RakeTask.new(:test_details) do |spec|
  spec.rspec_opts = '--color --format documentation'
  spec.pattern = FileList['spec/**/*_spec.rb']
end
task spec: :test

task default: :test
