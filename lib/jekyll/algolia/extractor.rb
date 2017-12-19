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
      # TOTEST
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
          record = apply_hook_each(record, node)
          next if record.nil?

          records << record
        end

        records
      end

      # Public: Apply the hook_before_indexing_each hook to the record.
      # Returning nil from this hook will skip the record. If the record has
      # been changed from the hook, its internal objectID should be updated
      # accordingly.
      #
      # record - The hash of the record to be pushed
      # node - The Nokogiri node of the element
      def self.apply_hook_each(record, node)
        hooked_record = Jekyll::Algolia.hook_before_indexing_each(record, node)
        return nil if hooked_record.nil?

        # If the record has been changed, we need to update its objectID
        if hooked_record != record
          record = hooked_record
          record[:objectID] = AlgoliaHTMLExtractor.uuid(hooked_record)
        end
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
