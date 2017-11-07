require 'algoliasearch'

module Jekyll
  module Algolia
    # Module to push records to Algolia and configure the index
    module Indexer
      include Jekyll::Algolia

      # Public: Push all records to Algolia and configure the index
      #
      # records - Records to push
      def self.run(records)
        ap records
        # checker = AlgoliaSearchCredentialChecker.new(@config)
        # checker.assert_valid

        # Jekyll.logger.info '=== DRY RUN ===' if @is_dry_run

        # @is_lazy_update ? lazy_update(items) : greedy_update(items)
      end
    end
  end
end
