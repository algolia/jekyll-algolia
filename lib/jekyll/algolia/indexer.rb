require 'algoliasearch'

module Jekyll
  module Algolia
    # Module to push records to Algolia and configure the index
    module Indexer
      include Jekyll::Algolia
      @index = nil

      def self.init
        ::Algolia.init(
          application_id: Configurator.application_id,
          api_key: Configurator.api_key
        )
        @index = index(Configurator.index_name)

        set_user_agent
      end

      def self.set_user_agent; end

      def self.index(index_name)
        ::Algolia::Index.new(index_name)
      end

      def self.update_records(index, records)
        index.add_objects!(records)
      end

      def self.delete_records_by_id(index, ids)
        index.delete_objects!(ids)
      end

      def self.remote_object_ids(index)
        list = []
        index.browse(attributesToRetrieve: 'objectID') do |hit|
          list << hit['objectID']
        end
        list.sort
      end

      def self.indexing_diff(records)
        # Getting list of objectID in remote and locally
        remote_ids = remote_object_ids(@index)
        local_ids = records.map { |record| record[:objectID] }.sort

        # Delete remote records that are no longer available locally
        delete_records_by_id(@index, remote_ids - local_ids)

        # Add only records that are not yet already in the remote
        new_records_ids = local_ids - remote_ids
        new_records = records.select do |record| 
          new_records_ids.include?(record[:objectID])
        end
        update_records(@index, new_records)

        update_settings(@index, Configurator.settings)
      end

      def self.update_settings(index, settings)
        index.set_settings(settings)
      end


      # Public: Push all records to Algolia and configure the index
      #
      # records - Records to push
      def self.run(records)
        init

        indexing_diff(records)

        # checker = AlgoliaSearchCredentialChecker.new(@config)
        # checker.assert_valid

        # Jekyll.logger.info '=== DRY RUN ===' if @is_dry_run

        # @is_lazy_update ? lazy_update(items) : greedy_update(items)
      end
    end
  end
end
