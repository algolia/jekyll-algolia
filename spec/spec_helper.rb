require 'awesome_print'
require_relative './spec_helper_jekyll.rb'
require_relative './spec_helper_simplecov.rb'
require './lib/push.rb'

RSpec.configure do |config|
  config.filter_run(focus: true)
  config.run_all_when_everything_filtered = true

  # Build a jekyll site, creating access to @__files used internally
  def get_site(config = {})
    config = config.merge(
      source: File.expand_path('./spec/fixtures')
    )
    config = Jekyll.configuration(config)
    site = Jekyll::Site.new(config)

    # Keep a list of all files
    def site.write
      @__files = {}
      each_site_file do |file|
        @__files[file.path] = file
      end
    end

    def site.file_by_name(file_name)
      @__files.find { |path, _| path =~ /#{file_name}$/ }[1]
    end

    site.process
    site
  end
end
