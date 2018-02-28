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

RSpec.configure do |config|
  config.filter_run(focus: true)
  config.fail_fast = true
  config.run_all_when_everything_filtered = true
  config.before do
    Jekyll::Algolia::Configurator.init
  end
end

# We will run all our tests with a real Jekyll instance, to make sure it works
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
  site = algolia_command.site

  # We mock the .write method to prevent it from actually doing anything
  allow(site).to receive(:write)

  # We monkey patch it to add a new method that will allow us to more easily
  # access the files that are processed by Jekyll, and return an actual instance
  # of Jekyll::File
  def site.__find_file(needle)
    # Note: We need to monkey patch here and not use a method accepting a site
    # as input because the `each_site_file` iterator is only accessible from
    # inside the class
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
  algolia_command.run

  site
end
