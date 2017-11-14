require 'algoliasearch'

module Jekyll
  module Algolia
    # Module to push records to Algolia and configure the index
    module Indexer
      include Jekyll::Algolia

      # Public: Init the module
      #
      # This call will instanciate the Algolia API client, set the custom
      # User Agent and give an easy access to the main index
      def self.init
        ::Algolia.init(
          application_id: Configurator.application_id,
          api_key: Configurator.api_key
        )

        set_user_agent
      end

      def self.set_user_agent; end

      # Public: Returns an Algolia Index object from an index name
      #
      # index_name - String name of the index
      def self.index(index_name)
        ::Algolia::Index.new(index_name)
      end

      # Public: Update records of the specified index
      #
      # index - Algolia Index to update
      # records - Array of records to update
      #
      # New records will be automatically added. Technically existing records
      # should be updated but this case should never happen as changing a record
      # content will change its objectID as well.
      def self.update_records(index, records)
        batch_size = Configurator.algolia('indexing_batch_size')
        records.each_slice(batch_size) do |batch|
          index.add_objects!(batch)
        end
      end

      # Public: Delete records whose objectIDs are passed
      #
      # index - Algolia Index to target
      # ids - Array of objectIDs to delete
      def self.delete_records_by_id(index, ids)
        index.delete_objects!(ids)
      end

      # Public: Returns an array of all the objectIDs in the index
      #
      # index - Algolia Index to target
      #
      # The returned array is sorted. It won't have any impact on the way it is
      # processed, but makes debugging easier when comparing arrays is needed.
      def self.remote_object_ids(index)
        list = []
        index.browse(attributesToRetrieve: 'objectID') do |hit|
          list << hit['objectID']
        end
        list.sort
      end

      # Public: Returns an array of the local objectIDs
      #
      # records - Array of all local records
      def self.local_object_ids(records)
        records.map { |record| record[:objectID] }.sort
      end

      # Public: Index content following the "diff" indexing mode
      #
      # records - Array of local records
      #
      # The "diff" indexing mode will only push new content to the index and
      # remove old content from it. It won't touch records that haven't been
      # updated. It will be a bit slower as it will first need to get the list
      # of all records in the index, but it will consume less operations than
      # the "atomic" indexing mode.
      def self.run_diff_mode(records)
        index = index(Configurator.index_name)
        # Getting list of objectID in remote and locally
        remote_ids = remote_object_ids(index)
        local_ids = local_object_ids(records)

        # Delete remote records that are no longer available locally
        delete_records_by_id(index, remote_ids - local_ids)

        # Add only records that are not yet already in the remote
        new_records_ids = local_ids - remote_ids
        new_records = records.select do |record|
          new_records_ids.include?(record[:objectID])
        end
        update_records(index, new_records)

        # Update settings
        update_settings(index, Configurator.settings)
      end

      # Public: Update settings of the index
      #
      # index - The Algolia Index
      # settings - The hash of settings to pass to the index
      def self.update_settings(index, settings)
        index.set_settings(settings)
      end

      # Public: Push all records to Algolia and configure the index
      #
      # records - Records to push
      def self.run(records)
        init

        run_diff_mode(records)

        # checker = AlgoliaSearchCredentialChecker.new(@config)
        # checker.assert_valid

        # Jekyll.logger.info '=== DRY RUN ===' if @is_dry_run

        # @is_lazy_update ? lazy_update(items) : greedy_update(items)
      end
    end
  end
end
