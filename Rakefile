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
require 'algoliasearch'
require 'rake'
require 'rspec/core'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

# LINT
desc 'Check files for linting issues'
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
desc 'Run unit tests'
RSpec::Core::RakeTask.new(:test) do |task|
  task.rspec_opts = '--color --format progress'
  task.pattern = [
    'spec/*.rb',
    'spec/jekyll/**/*.rb'
  ]
end
namespace 'test' do
  desc 'Run tests in all Ruby versions'
  task :all_ruby_versions do
    puts 'Please, run ./scripts/test_all_ruby_versions manually'
  end

  # Generate locally browsable coverage files
  task :coverage do
    ENV['COVERAGE'] = 'true'
    Rake::Task['test'].execute
  end

  desc 'Live-reload unit tests'
  task :watch do
    # We specifically watch for ./lib and ./spec and not the whole dir because:
    # 1. It's the only directories we are interested in
    # 2. Listening to the whole parent dir might throw Guard errors if we have
    #    symlink
    sh 'bundle exec guard --clear --watchdir lib spec'
  end

  # Integration tests need to run `bundle exec jekyll build/algolia`. Using
  # bundle from inside a Rakefile does not seem to work, so the scripts have to
  # be run manually. Each script run the needed commands to prepare the test
  # site, then actually run the _run and _watch_run tasks below.
  desc 'Run integration tests'
  task :integration do
    puts 'Please, run ./scripts/test_integration manually'
  end
  namespace 'integration' do
    desc 'Live-reload integration tests'
    task :watch do
      puts 'Please, run ./scripts/test_integration_watch manually'
    end
    # Delete the test index
    task :_delete_index do
      Algolia.init(
        application_id: ENV['ALGOLIA_APPLICATION_ID'],
        api_key: ENV['ALGOLIA_API_KEY']
      )
      Algolia::Index.new(ENV['ALGOLIA_INDEX_NAME']).delete_index!
    end
    # Run only the integration tests
    desc ''
    RSpec::Core::RakeTask.new(:_run) do |task|
      task.rspec_opts = '--color --format progress'
      task.pattern = [
        # Check that the default build has the expected results
        'spec/integration/main_spec.rb',
        # Now check various config and its impact on the settings
        'spec/integration/settings_spec.rb'
      ]
    end
    # Live-reloading integration tests
    # It will reload the tests whenever they are changed. It will not
    # live-rebuild everything, you still have to run rake
    # ./scripts/test_integration_prepare for that
    task :_watch_run do
      sh 'bundle exec guard '\
         '--clear '\
         '--watchdir lib spec/integration '\
         '--guardfile Guardfile_integration'
    end
  end
end
task watch: 'test:watch'

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
  # Getting up to date from master
  task :update_develop_from_master do
    sh 'git checkout master --quiet'
    sh 'git pull --rebase origin master --quiet'
    sh 'git checkout develop --quiet'
    sh 'git rebase master --quiet'
  end
  # Update current version
  task :update_version do
    version_file_path = 'lib/jekyll/algolia/version.rb'
    require_relative version_file_path

    # Ask for new version
    old_version = Jekyll::Algolia::VERSION.to_s
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
    last_tag = `git describe --tags --abbrev=0`.strip
    changelog = `git log #{last_tag}..HEAD --format=%B`.gsub("\n\n", "\n")
    tag_name = new_version
    sh 'git tag '\
      "-a #{tag_name} "\
      "-m \"#{changelog}\""\
      ' 2>/dev/null'

    sh "git tag #{tag_name} #{tag_name} -f -a"
  end
  # Build the gem
  task :build do
    sh 'bundle install'
    sh 'gem build jekyll-algolia.gemspec'
  end
  # Push the gem to rubygems
  task :push do
    # This will throw a warning because we're redefining a constant. That's ok.
    load 'lib/jekyll/algolia/version.rb'
    current_version = Jekyll::Algolia::VERSION.to_s
    sh "gem push jekyll-algolia-#{current_version}.gem"
    sh "rm jekyll-algolia-#{current_version}.gem"
    sh "git push origin #{current_version}"
  end
  # Update master
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
    sh "git commit -m 'Updating documentation website' || true"

    sh 'git checkout master --quiet'
    sh 'git rebase develop --quiet'
    sh 'git push origin master'

    sh 'git checkout develop --quiet'
  end
  desc 'Serve the documentation locally'
  task :serve do
    Dir.chdir('./docs-src') do
      sh 'yarn'
      sh 'yarn run serve'
    end
  end
end

task default: :test
