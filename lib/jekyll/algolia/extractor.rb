# frozen_string_literal: true

require 'algolia_html_extractor'

module Jekyll
  module Algolia
    # Module to extract records from Jekyll files
    module Extractor
      include Jekyll::Algolia

      # Public: Extract records from the file
      #
      # file - The Jekyll file to process
      def self.run(file)
        # Getting all hierarchical nodes from the HTML input
        raw_records = extract_raw_records(file.content)
        # Getting file metadata
        shared_metadata = FileBrowser.metadata(file)

        # Building the list of records
        records = []
        raw_records.map do |record|
          # We do not need to pass the HTML node element to the final record
          node = record[:node]
          record.delete(:node)

          # Merging each record info with file info
          record = Utils.compact_empty(record.merge(shared_metadata))

          # Apply custom user-defined hooks
          # Users can return `nil` from the hook to signal we should not index
          # such a record
          record = Hooks.apply_each(record, node)
          next if record.nil?

          records << record
        end

        records
      end

      # Public: Adds a unique :objectID field to the hash, representing the
      # current content of the record
      def self.add_unique_object_id(record)
        record[:objectID] = AlgoliaHTMLExtractor.uuid(record)
        record
      end

      # Public: Extract raw records from the file, including content for each
      # node to index and hierarchy
      #
      # content - The HTML content to parse
      def self.extract_raw_records(content)
        AlgoliaHTMLExtractor.run(
          content,
          options: {
            css_selector: Configurator.algolia('nodes_to_index')
          }
        )
      end
    end
  end
end
