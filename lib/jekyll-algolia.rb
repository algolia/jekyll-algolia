# frozen_string_literal: true

require 'jekyll/commands/algolia'
require 'jekyll/algolia/overwrites/jekyll-algolia-site'
require 'jekyll/algolia/overwrites/jekyll-document'
require 'jekyll/algolia/overwrites/jekyll-tags-link'
require 'date'

module Jekyll
  # Requirable file, loading all dependencies.
  # Methods here are called by the main `jekyll algolia` command
  module Algolia
    require 'jekyll/algolia/configurator'
    require 'jekyll/algolia/error_handler'
    require 'jekyll/algolia/extractor'
    require 'jekyll/algolia/file_browser'
    require 'jekyll/algolia/hooks'
    require 'jekyll/algolia/indexer'
    require 'jekyll/algolia/logger'
    require 'jekyll/algolia/progress_bar'
    require 'jekyll/algolia/utils'
    require 'jekyll/algolia/version'

    # Public: Init the Algolia module
    #
    # config - A hash of Jekyll config option (merge of _config.yml options and
    # options passed on the command line)
    #
    # The gist of the plugin works by instanciating a Jekyll site,
    # monkey-patching its `write` method and building it.
    def self.init(config = {})
      config = Configurator.init(config).config
      @site = Jekyll::Algolia::Site.new(config)

      exit 1 unless Configurator.assert_valid_credentials

      Configurator.warn_of_deprecated_options

      # Register our own tags to overwrite the default tags
      Liquid::Template.register_tag('link', JekyllAlgoliaLink)

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
  end
end
