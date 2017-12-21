# frozen_string_literal: true

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
    'spec/**/*.rb'
  ]
  task.options = [
    '--display-cop-names',
    '--force-exclusion' # Some files are excluded in .rubocop.yml
  ]
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
  puts 'Please, run ./scripts/test_all_ruby_versions manually'
end

# COVERAGE
desc 'Generate locally browsable coverage files'
task :coverage do
  ENV['COVERAGE'] = 'true'
  Rake::Task['test'].execute
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

# GEM RELEASE
desc 'Release a new version of the gem'
task release: %i[lint test] do
  Rake::Task['release:update_develop_from_master'].invoke
  Rake::Task['release:update_version'].invoke
  Rake::Task['release:build'].invoke
  Rake::Task['release:push'].invoke
  Rake::Task['release:update_master_from_develop'].invoke
end
namespace 'release' do
  desc 'Getting up to date from master'
  task :update_develop_from_master do
    sh 'git checkout master --quiet'
    sh 'git pull --rebase origin master --quiet'
    sh 'git checkout develop --quiet'
    sh 'git rebase master --quiet'
  end
  desc 'Update current version'
  task :update_version do
    version_file_path = 'lib/jekyll/algolia/version.rb'
    require_relative version_file_path

    # Ask for new version
    old_version = AlgoliaHTMLExtractorVersion.to_s
    puts "Current version is #{old_version}"
    puts 'Enter new version:'
    new_version = STDIN.gets.strip

    # Write it to file
    version_file_content = File.open(version_file_path, 'rb').read
    version_file_content.gsub!(old_version, new_version)
    File.write(version_file_path, version_file_content)

    # Commit it in git
    sh "git commit -a -m 'release #{new_version}'"
    # Create the git tag
    sh "git tag -am 'tag v#{new_version}' #{new_version}"
  end
  desc 'Build the gem'
  task :build do
    sh 'bundle install'
    sh 'gem build jekyll-algolia.gemspec'
  end
  desc 'Push the gem to rubygems'
  task :push do
    load 'lib/jekyll/algolia/version.rb'
    current_version = AlgoliaHTMLExtractorVersion.to_s
    sh "gem push jekyll-algolia-#{current_version}.gem"
    sh "rm jekyll-algolia-#{current_version}.gem"
    sh "git push origin #{current_version}"
  end
  desc 'Update master'
  task :update_master_from_develop do
    sh 'git checkout master --quiet'
    sh 'git rebase develop --quiet'
    sh 'git checkout develop --quiet'
  end
end

# DOCUMENTATION
namespace 'docs' do
  desc 'Rebuild documentation website'
  task :build do
    Dir.chdir('./docs-src') do
      sh 'yarn'
      sh 'yarn run build'
    end
  end
  desc 'Rebuild and deploy documentation'
  task :deploy do
    # Make sure develop is up to date with master
    sh 'git checkout master --quiet'
    sh 'git pull --rebase origin master --quiet'
    sh 'git checkout develop --quiet'
    sh 'git rebase master --quiet'

    Rake::Task['docs:build'].invoke
    sh 'git add ./docs'
    sh "git commit -m 'Updating documentation website'"

    sh 'git checkout master --quiet'
    sh 'git rebase develop --quiet'
    sh 'git push origin master'

    sh 'git checkout develop --quiet'
  end
end

task default: :test
