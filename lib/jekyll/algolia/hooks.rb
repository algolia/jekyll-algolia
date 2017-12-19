# frozen_string_literal: true

module Jekyll
  module Algolia
    # Applying user-defined hooks on the processing pipeline
    module Hooks
      # Public: Apply the before_indexing_each hook to the record.
      # This method is a simple wrapper around methods that can be overwritten
      # by users. Using a wrapper around it makes testing their behavior easier
      # as they can be mocked in tests.
      #
      # record - The hash of the record to be pushed
      # node - The Nokogiri node of the element
      def self.apply_each(record, node)
        before_indexing_each(record, node)
      end

      # Public: Apply the before_indexing_all hook to all records.
      # This method is a simple wrapper around methods that can be overwritten
      # by users. Using a wrapper around it makes testing their behavior easier
      # as they can be mocked in tests.
      #
      # records - The list of all records to be indexed
      def self.apply_all(records)
        before_indexing_all(records)
      end

      # Public: Check if the file should be indexed or not
      #
      # filepath - The path to the file, before transformation
      #
      # This hook allow users to define if a specific file should be indexed or
      # not. Basic exclusion can be done through the `files_to_exclude` option,
      # but a custom hook like this one can allow more fine-grained
      # customisation.
      def self.should_be_excluded?(_filepath)
        false
      end

      # Public: Custom method to be run on the record before indexing it
      #
      # record - The hash of the record to be pushed
      # node - The Nokogiri node of the element
      #
      # Users can modify the record (adding/editing/removing keys) here. It can
      # be used to remove keys that should not be indexed, or access more
      # information from the HTML node.
      #
      # Users can return nil to signal that the record should not be indexed
      def self.before_indexing_each(record, _node)
        record
      end

      # Public: Custom method to be run on the list of all records before
      # indexing them
      #
      # records - The list of all records to be indexed
      #
      # Users can modify the full list from here. It might provide an easier
      # interface than `hook_before_indexing_each` when knowing the full context
      # is necessary
      def self.before_indexing_all(records)
        records
      end
    end
  end
end
