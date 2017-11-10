module Jekyll
  module Algolia
    # Single source of truth for access to configuration variables
    module Configurator
      # Algolia default values
      ALGOLIA_DEFAULTS = {
        'extensions_to_index' => nil,
        'files_to_exclude' => nil,
        'nodes_to_index' => 'p'
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
    end
  end
end
