require 'jekyll/commands/algolia'

module Jekyll
  # Requirable file, loading all dependencies. 
  # Methods here are called by the main `jekyll algolia` command
  module Algolia
    # Holds the current plugin version
    require 'jekyll/algolia/version'
    # Extracts records from Jekyll files
    require 'jekyll/algolia/extractor'
    # Read configuration options
    require 'jekyll/algolia/configurator'
    # Push records to Algolia
    require 'jekyll/algolia/indexer'


    # Public: Init the Algolia module
    #
    # config - A hash of Jekyll config option (merge of _config.yml options and
    # options passed on the command line)
    #
    # Returns itself
    def self.init(config = {})
      @config = config
      # @checker = AlgoliaSearchCredentialChecker.new(@config)
      self
    end

    # Public: Run the main Algolia module
    #
    # The gist of the plugin works by instanciating a Jekyll site,
    # monkey-patching its `write` method and building it.
    def self.run
      site = Jekyll::Site.new(@config)
      monkey_patch_site(site)
      site.process
    end

    # Public: Get access to the Jekyll config
    #
    # All other classes will need access to this config, so we make it publicly
    # accessible
    def self.config
      @config
    end

    # Public: Replace the main `write` method of the site to push records to
    # Algolia instead of writing files to disk.
    #
    # site - The Jekyll site to monkey patch
    #
    # We will change the behavior of the `write` method that should write files
    # to disk and have it create JSON records and push them to Algolia instead.
    def self.monkey_patch_site(site)
      def site.write
        records = []
        # is_verbose = config['verbose']
        each_site_file do |file|
          # # Skip files that should not be indexed
          # next unless AlgoliaSearchJekyllPush.indexable?(file)
          # Jekyll.logger.info "Extracting data from #{file.path}" if is_verbose
          #
          file_records = Jekyll::Algolia::Extractor.run(file)
          # new_items = AlgoliaSearchRecordExtractor.new(file).extract
          # next if new_items.nil?
          # ap new_items if is_verbose
          #
          records += file_records
        end

        Jekyll::Algolia::Indexer.run(records)
      end
    end
  end
end
