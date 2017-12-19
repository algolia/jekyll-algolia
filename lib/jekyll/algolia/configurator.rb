# frozen_string_literal: true

module Jekyll
  module Algolia
    # Single source of truth for access to configuration variables
    module Configurator
      include Jekyll::Algolia

      # Algolia default values
      ALGOLIA_DEFAULTS = {
        'extensions_to_index' => nil,
        'files_to_exclude' => nil,
        'nodes_to_index' => 'p',
        'indexing_batch_size' => 1000,
        'indexing_mode' => 'diff',
        'settings' => {
          'distinct' => true,
          'attributeForDistinct' => 'url',
          'attributesForFaceting' => %w[tags type title],
          'customRanking' => [
            'desc(date)',
            'desc(weight.heading)',
            'asc(weight.position)'
          ],
          'highlightPreTag' => '<em class="ais-Highlight">',
          'highlightPostTag' => '</em>',
          'searchableAttributes' => %w[
            title
            hierarchy.lvl0
            hierarchy.lvl1
            hierarchy.lvl2
            hierarchy.lvl3
            hierarchy.lvl4
            hierarchy.lvl5
            unordered(content)
            collection,unordered(categories),unordered(tags)
          ]
        }
      }.freeze

      # Public: Get the value of a specific Jekyll configuration option
      #
      # key - Key to read
      #
      # Returns the value of this configuration option, nil otherwise
      def self.get(key)
        Jekyll::Algolia.config[key]
      end

      # Public: Get the value of a specific Algolia configuration option, or
      # revert to the default value otherwise
      #
      # key - Algolia key to read
      #
      # Returns the value of this option, or the default value
      def self.algolia(key)
        config = get('algolia') || {}
        value = config[key] || ALGOLIA_DEFAULTS[key]

        # No value found but we have a method to define the default value
        if value.nil? && respond_to?("default_#{key}")
          value = send("default_#{key}")
        end

        value
      end

      # Public: Return the application id
      #
      # Will first try to read the ENV variable, and fallback to the one
      # configured in Jekyll config
      def self.application_id
        ENV['ALGOLIA_APPLICATION_ID'] || algolia('application_id')
      end

      # Public: Return the api key
      #
      # Will first try to read the ENV variable. Will otherwise try to read the
      # _algolia_api_key file in the Jekyll folder
      def self.api_key
        # Alway taking the ENV variable first
        return ENV['ALGOLIA_API_KEY'] if ENV['ALGOLIA_API_KEY']

        # Reading from file on disk otherwise
        source_dir = get('source')
        if source_dir
          api_key_file = File.join(source_dir, '_algolia_api_key')
          if File.exist?(api_key_file) && File.size(api_key_file).positive?
            return File.open(api_key_file).read.strip
          end
        end

        nil
      end

      # Public: Return the index name
      #
      # Will first try to read the ENV variable, and fallback to the one
      # configured in Jekyll config
      def self.index_name
        ENV['ALGOLIA_INDEX_NAME'] || algolia('index_name')
      end

      # Public: Get the index settings
      #
      # This will be a merge of default settings and the one defined in the
      # _config.yml file
      def self.settings
        user_settings = algolia('settings') || {}
        ALGOLIA_DEFAULTS['settings'].merge(user_settings)
      end

      # Public: Return the current indexing mode
      #
      # Default mode is `diff`, but users can configure their own by updating
      # the `indexing_mode` config in _config.yml. The only other authorized
      # value is `atomic`. If an unrecognized mode is defined, it defaults to
      # `diff`.
      def self.indexing_mode
        mode = algolia('indexing_mode') || ALGOLIA_DEFAULTS['indexing_mode']
        return 'diff' unless %w[diff atomic].include?(mode)
        mode
      end

      # Public: Check that all credentials are set
      #
      # Returns true if everything is ok, false otherwise. Will display helpful
      # error messages for each missing credential
      def self.assert_valid_credentials
        checks = %w[application_id index_name api_key]
        checks.each do |check|
          if send(check.to_sym).nil?
            Logger.known_message("missing_#{check}")
            return false
          end
        end

        true
      end

      # Public: Setting a default values to index only html and markdown files
      #
      # Markdown files can have many different extensions. We keep the one
      # defined in the Jekyll config
      def self.default_extensions_to_index
        ['html'] + get('markdown_ext').split(',')
      end

      # Public: Setting a default value to ignore index.html/index.md files in
      # the root
      #
      # Chances are high that the main page is not worthy of indexing (it can be
      # the list of the most recent posts or some landing page without much
      # content). We ignore it by default.
      #
      # User can still add it by manually specifying a `files_to_exclude` to an
      # empty array
      def self.default_files_to_exclude
        algolia('extensions_to_index').map do |extension|
          "index.#{extension}"
        end
      end

      # Public: Returns true if the command is run in verbose mode
      #
      # When set to true, more logs will be displayed
      def self.verbose?
        value = get('verbose')
        return true if value == true
        false
      end

      # Public: Returns true if the command is run in verbose mode
      #
      # When set to true, no indexing operations will be sent to the API
      def self.dry_run?
        value = get('dry_run')
        return true if value == true
        false
      end
    end
  end
end
