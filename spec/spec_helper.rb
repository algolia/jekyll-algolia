# frozen_string_literal: true

# Generate coverage when run locally with rake coverage
require_relative './spec_helper_simplecov.rb' if ENV['COVERAGE']
# Load coverage when run through Travis
if ENV['TRAVIS']
  require 'coveralls'
  Coveralls.wear!
end

require 'jekyll'
require 'jekyll-algolia'
require 'ostruct'

RSpec.configure do |config|
  config.filter_run(focus: true)
  config.fail_fast = false
  config.run_all_when_everything_filtered = true
  config.before do
    Jekyll::Algolia::Configurator.init
  end
end

# We will run our tests with a real Jekyll instance, to make sure it works
# with the real beast.
def init_new_jekyll_site(user_config = {})
  # We start a new Jekyll site, using our ./spec/site directory as its starting
  # point
  config = Jekyll.configuration(
    user_config.merge(
      source: File.expand_path('./spec/site')
    )
  )
  algolia_command = Jekyll::Algolia.init(config)

  # Silence the progress bars. We couldn't use a double here as it would leak
  # across tests and this is not allowed by rspec.
  fake_progress_bar = OpenStruct.new
  fake_progress_bar.increment = nil
  allow(ProgressBar)
    .to receive(:create)
    .and_return(fake_progress_bar)

  site = algolia_command.site

  # We monkey patch it to add a new method that will allow us to more easily
  # access the files that are processed by Jekyll, and return an actual instance
  # of Jekyll::File
  def site.__find_file(needle)
    each_site_file do |file|
      return file if file.path =~ /#{needle}$/
    end
    nil
  end

  def site.__all_files
    each_site_file do |file|
      puts file.path
    end
  end

  # We have to run the command to actually initialize the Jekyll site so
  # it populates its list of internal files
  allow(site).to receive(:push)
  algolia_command.run

  site
end
