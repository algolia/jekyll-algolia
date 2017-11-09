module Jekyll
  module Algolia
    # Single source of truth for access to configuration variables
    module Configurator
      # Algolia default values
      ALGOLIA_DEFAULTS = {
        'extensions_to_index' => nil,
        'files_to_exclude' => ['index.html'],
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

        if !value && key == 'extensions_to_index'
          value = default_extensions_to_index
        end

        value
      end

      # Public: Setting a default values to index only html and markdown files
      #
      # Markdown files can have many different extensions. We keep the one
      # defined in the Jekyll config
      def self.default_extensions_to_index
        extensions = ['html']
        extensions += get('markdown_ext').split(',')
        extensions.join(',')
      end
    end
  end
end
