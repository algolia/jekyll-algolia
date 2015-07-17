if ENV['TRAVIS']
  require 'coveralls'
  Coveralls.wear!
end

require 'awesome_print'
require_relative './spec_helper_jekyll.rb'
require_relative './spec_helper_simplecov.rb'
require './lib/push.rb'

RSpec.configure do |config|
  config.filter_run(focus: true)
  config.run_all_when_everything_filtered = true

  # Create a Jekyll::Site instance, patched with a `file_by_name` method
  def get_site(config = {}, options = {})
    default_options = {
      mock_write_method: true,
      process: true
    }
    options = default_options.merge(options)

    config = config.merge(
      source: File.expand_path('./spec/fixtures')
    )
    config = Jekyll.configuration(config)

    site = AlgoliaSearchJekyllPush.jekyll_new(config)

    def site.file_by_name(file_name)
      each_site_file do |file|
        return file if file.path =~ /#{file_name}$/
      end
    end

    allow(site).to receive(:write) if options[:mock_write_method]

    site.process if options[:process]
    site
  end
end
