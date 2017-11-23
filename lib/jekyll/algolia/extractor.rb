# frozen_string_literal: true

# require 'algoliasearch'
# require 'json'
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
          node = record[:node]
          record.delete(:node)

          # Merging each record info with file info
          record = Utils.compact_empty(record.merge(shared_metadata))

          # Apply custom user-defined hooks
          record = Jekyll::Algolia.hook_before_indexing_each(record, node)

          # Users can return `nil` from the hook to signal we should not index
          # such a record
          next if record.nil?

          records << record
        end

        records
      end

      # Public: Extract raw records from the file, including content for each
      # node to index and hierarchy
      #
      # content - The HTML content to parse
      def self.extract_raw_records(content)
        AlgoliaHTMLExtractor.new(
          content,
          options: {
            css_selector: Configurator.algolia('nodes_to_index')
          }
        ).extract
      end
    end
  end
end
