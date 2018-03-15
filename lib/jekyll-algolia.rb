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

    # A Jekyll::Site subclass that overrides process from the parent class to
    # create JSON records out of rendered documents and push those records to
    # Algolia instead of writing files to disk.
    class Site < Jekyll::Site
      # We expose a way to reset the collection, as it will be needed in the
      # tests
      attr_writer :collections

      # Public: Overwriting the parent method
      #
      # This will prepare the website, gathering all files, excluding the one we
      # don't need to index, then render them (converting to HTML), the finally
      # calling `push` to push to Algolia
      def process
        # Default Jekyll preflight
        reset
        read
        generate

        # Removing all files that won't be indexed, so we don't waste time
        # rendering them
        keep_only_indexable_files

        # Converting them to HTML
        render

        # Pushing them Algolia
        push
      end

      # Public: Filtering a list of items to only keep the one that are
      # indexable.
      #
      # items - List of Pages/Documents
      #
      # Note: It also sets the layout to nil, to further speed up the rendering
      def indexable_list(items)
        new_list = []
        items.each do |item|
          next unless FileBrowser.indexable?(item)

          item.data = {} if item.data.nil?
          item.data['layout'] = nil
          new_list << item
        end
        new_list
      end

      # Public: Removing non-indexable Pages, Posts and Documents from the
      # internals
      def keep_only_indexable_files
        @pages = indexable_list(@pages)

        # Applying to each collections
        @collections.each_value do |collection|
          collection.docs = indexable_list(collection.docs)
        end

        # Remove all static files
        @static_files = []
      end

      # Public: Extract records from every file and index them
      def push
        records = []
        files = []
        each_site_file do |file|
          # Even if we cleared the list of documents/pages beforehand, some
          # files might still sneak up to this point (like static files added to
          # a collection directory), so we check again if they can really be
          # indexed.
          next unless FileBrowser.indexable?(file)

          path = FileBrowser.relative_path(file.path)

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
