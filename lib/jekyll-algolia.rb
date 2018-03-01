# frozen_string_literal: true

require 'jekyll/commands/algolia'
require 'date'

module Jekyll
  # Requirable file, loading all dependencies.
  # Methods here are called by the main `jekyll algolia` command
  module Algolia
    require 'jekyll/algolia/version'
    require 'jekyll/algolia/utils'
    require 'jekyll/algolia/hooks'
    require 'jekyll/algolia/configurator'
    require 'jekyll/algolia/logger'
    require 'jekyll/algolia/error_handler'
    require 'jekyll/algolia/file_browser'
    require 'jekyll/algolia/extractor'
    require 'jekyll/algolia/indexer'

    # Public: Init the Algolia module
    #
    # config - A hash of Jekyll config option (merge of _config.yml options and
    # options passed on the command line)
    #
    # The gist of the plugin works by instanciating a Jekyll site,
    # monkey-patching its `write` method and building it.
    def self.init(config = {})
      @start_time = Time.now
      config = Configurator.init(config).config
      @site = Jekyll::Algolia::Site.new(config)

      exit 1 unless Configurator.assert_valid_credentials

      Configurator.warn_of_deprecated_options

      if Configurator.dry_run?
        Logger.log('W:==== THIS IS A DRY RUN ====')
        Logger.log('W:  - No records will be pushed to your index')
        Logger.log('W:  - No settings will be updated on your index')
      end

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
      Logger.log('I:Processing site...')
      @site.process
    end

    # Public: Get access to the Jekyll site
    #
    # Tests will need access to the inner Jekyll website so we expose it here
    def self.site
      @site
    end

    # Public: Get access to the time at which the command was run
    #
    # Jekyll will always set the updated time of pages to the time of the build
    # run. The plugin needs those values to stay at nil if they did not change,
    # so we'll keep track of the time at build time and revert any page build at
    # that time to nil.
    def self.start_time
      @start_time
    end

    # A Jekyll::Site subclass that overrides #write from the parent class to
    # create JSON records out of rendered documents and push those records to
    # Algolia instead of writing files to disk.
    class Site < Jekyll::Site
      # We make the cleanup method a noop, otherwise it will remove excluded
      # files from destination
      def cleanup; end

      def write
        records = []
        files = []
        Logger.log('I:Extracting records...')
        each_site_file do |file|
          path = FileBrowser.relative_path(file)

          # Skip files that should not be indexed
          is_indexable = FileBrowser.indexable?(file)
          unless is_indexable
            Logger.verbose("W:Skipping #{path}")
            next
          end

          Logger.verbose("I:Extracting records from #{path}")
          file_records = Extractor.run(file)

          files << file
          records += file_records
        end

        # Applying the user hook on the whole list of records
        records = Hooks.apply_all(records)

        # Adding a unique objectID to each record
        records.map! do |record|
          Extractor.add_unique_object_id(record)
        end

        Logger.verbose("I:Found #{files.length} files")

        Indexer.run(records)
      end
    end
  end
end
