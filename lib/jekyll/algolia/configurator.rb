module Jekyll
  module Algolia
    # Single source of truth for access to configuration variables
    module Configurator
      # Algolia default values
      ALGOLIA_DEFAULTS = {
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
        config[key] || ALGOLIA_DEFAULTS[key]
      end
    end
  end
end
