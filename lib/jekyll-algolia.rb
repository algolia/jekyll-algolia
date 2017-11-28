# frozen_string_literal: true

require 'jekyll/commands/algolia'

module Jekyll
  # Requirable file, loading all dependencies.
  # Methods here are called by the main `jekyll algolia` command
  module Algolia
    require 'jekyll/algolia/version'
    require 'jekyll/algolia/utils'
    require 'jekyll/algolia/user_hooks'
    require 'jekyll/algolia/configurator'
    require 'jekyll/algolia/logger'
    require 'jekyll/algolia/error_handler'
    require 'jekyll/algolia/file_browser'
    require 'jekyll/algolia/extractor'
    require 'jekyll/algolia/indexer'

    @config = {}

    # Public: Init the Algolia module
    #
    # config - A hash of Jekyll config option (merge of _config.yml options and
    # options passed on the command line)
    #
    # The gist of the plugin works by instanciating a Jekyll site,
    # monkey-patching its `write` method and building it.
    def self.init(config = {})
      @config = config
      @site = Jekyll::Algolia::Site.new(@config)

      exit 1 unless Configurator.assert_valid_credentials

      self
    end

    # Public: Run the main Algolia module
    #
    # Actually "process" the site, which will acts just like a regular `jekyll
    # build` except that our monkey patched `write` method will be called
    # instead.
    #
    # Note: The internal list of files to be processed will only be created when
    # calling .process
    def self.run
      @site.process
    end

    # Public: Get access to the Jekyll config
    #
    # All other classes will need access to this config, so we make it publicly
    # accessible
    def self.config
      @config
    end

    # Public: Get access to the Jekyll site
    #
    # Tests will need access to the inner Jekyll website so we expose it here
    def self.site
      @site
    end

    # A Jekyll::Site subclass that overrides #write from the parent class to
    # create JSON records out of rendered documents and push those records
    # to Algolia instead of writing files to disk.
    class Site < Jekyll::Site
      def write
        if Configurator.dry_run?
          Logger.log('W:==== THIS IS A DRY RUN ====')
          Logger.log('W:  - No records will be pushed to your index')
          Logger.log('W:  - No settings will be updated on your index')
        end

        records = []
        files = []
        each_site_file do |file|
          # Skip files that should not be indexed
          is_indexable = FileBrowser.indexable?(file)
          unless is_indexable
            Logger.verbose("W:Skipping #{file.path}")
            next
          end

          path = FileBrowser.path_from_root(file)
          Logger.verbose("I:Extracting records from #{path}")
          file_records = Extractor.run(file)

          files << file
          records += file_records
        end

        # Applying the user hook on the whole list of records
        records = Jekyll::Algolia.hook_before_indexing_all(records)

        Logger.verbose("I:Found #{files.length} files")

        Indexer.run(records)
      end
    end
  end
end
