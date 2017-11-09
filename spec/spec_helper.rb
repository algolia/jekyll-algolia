# Load coverage when run through Travis
if ENV['TRAVIS']
  require 'coveralls'
  Coveralls.wear!
end

require 'jekyll'
require 'jekyll-algolia'
# require_relative './spec_helper_simplecov.rb'

RSpec.configure do |config|
  config.filter_run(focus: true)
  config.fail_fast = true
  config.run_all_when_everything_filtered = true
end

# We will run all our tests with a real Jekyll instance, to make sure it works
# with the real beast.
def init_new_jekyll_site
  # We start a new Jekyll site, using our ./spec/site directory as its starting
  # point
  config = Jekyll.configuration(
    source: File.expand_path('./spec/site')
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
  end

  def site.__all_files
    each_site_file do |file|
      puts file.path
    end
  end

  # We have to call run the command to  actually initialize the Jekyll Site so
  # it populates its list of internal files
  algolia_command.run

  site
end
#
# def get_file(site)
#
# end
#
#
#
#   def site.file_by_name(file_name)
#     files = {}
#
#     # We get the list of all classic files
#     each_site_file do |file|
#       files[file.path] = file
#     end
#
#     # If we have an exact match, we use that one:
#     return files[file_name] if files.key?(file_name)
#
#     # Otherwise we try to find a key that is loosely matching
#     keys = files.keys
#     values = files.values
#
#     keys.each_with_index do |key, index|
#       return values[index] if key =~ /#{file_name}$/
#     end
#
#     nil
#   end
# end

# # Create a Jekyll::Site instance, patched with a `file_by_name` method
# def get_site(config = {}, options = {})
#   default_options = {
#     mock_write_method: true,
#     process: true
#   }
#   options = default_options.merge(options)
#
#   config = config.merge(
#   )
#   config = Jekyll.configuration(config)
#
#   site = AlgoliaSearchJekyllPush.init_options({}, options, config)
#                                 .jekyll_new(config)
#
#
#   allow(site).to receive(:write) if options[:mock_write_method]
#
#   site.process if options[:process]
#   site
# end
#
# def mock_logger
#   # Spying on default logging method while still calling them
#   allow(Jekyll.logger).to receive(:info).and_wrap_original do |method, *args|
#     # Hiding the basic "Configuration file" display
#     next if args[0] == 'Configuration file:'
#     method.call(*args)
#   end
#   allow(Jekyll.logger).to receive(:warn).and_call_original
#   allow(Jekyll.logger).to receive(:error).and_call_original
# end
