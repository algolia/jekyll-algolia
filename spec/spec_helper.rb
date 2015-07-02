require 'jekyll'
require 'awesome_print'
require './lib/push.rb'

RSpec.configure do |config|
  config.filter_run(focus: true)
  config.run_all_when_everything_filtered = true

  # MockPage to simulate a Jekyll::Page
  class MockPage
    attr_accessor :name
    def initialize(name)
      @name = name
    end
  end

  # Build a jekyll site, creating access to @__files used internally
  def get_site(config = {})
    config = config.merge(
      source: File.expand_path('./spec/fixtures')
    )
    config = Jekyll.configuration(config)
    site = Jekyll::Site.new(config)
    # Overwrite write to not write on disk but keep a list of files
    def site.write
      @__files = []
      each_site_file do |file|
        next unless file.respond_to? :name
        @__files << file
      end
    end
    def site.file_by_name(name)
      @__files.find { |file| file.name == name }
    end
    site.process
    site
  end
end
