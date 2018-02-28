# frozen_string_literal: true

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

      # Public: Set the User-Agent to send to the API
      #
      # Every integrations should follow the "YYY Integration" pattern, and
      # every API client should follow the "Algolia for YYY" pattern. Even if
      # each integration version is pinned to a specific API client version, we
      # are explicit in defining it to help debug from the dashboard.
      def self.set_user_agent
        user_agent = [
          "Jekyll Integration (#{VERSION})",
          "Algolia for Ruby (#{::Algolia::VERSION})",
          "Jekyll (#{::Jekyll::VERSION})",
          "Ruby (#{RUBY_VERSION})"
        ].join('; ')

        ::Algolia.set_extra_header('User-Agent', user_agent)
      end

      # Public: Returns an Algolia Index object from an index name
      #
      # index_name - String name of the index
      def self.index(index_name)
        ::Algolia::Index.new(index_name)
      end

      # Public: Check if an index exists
      #
      # index_name - Name of the index
      #
      # Note: there is no API endpoint to do that, so we try to get the settings
      # instead, which will fail if the index does not exist
      def self.index?(index_name)
        index(index_name).get_settings
        return true
      rescue StandardError
        return false
      end

      # Public: Returns an array of all the objectIDs in the index
      #
      # index - Algolia Index to target
      #
      # The returned array is sorted. It won't have any impact on the way it is
      # processed, but makes debugging easier when comparing arrays is needed.
      def self.remote_object_ids(index)
        list = []
        Logger.verbose(
          "I:Inspecting existing records in index #{index.name}..."
        )
        begin
          index.browse(attributesToRetrieve: 'objectID') do |hit|
            list << hit['objectID']
          end
        rescue StandardError
          # The index might not exist if it's the first time we use the plugin
          # so we'll consider that it means there are no records there
          return []
        end
        list.sort
      end

      # Public: Returns an array of the local objectIDs
      #
      # records - Array of all local records
      def self.local_object_ids(records)
        records.map { |record| record[:objectID] }.compact.sort
      end

      # Public: Update settings of the index
      #
      # index - The Algolia Index
      #
      # Does nothing in dry run mode
      # Settings will only be updated in the first push, and if custom settings
      # are defined in _config.yml. Otherwise, they are left untouched, allowing
      # users to configure them through their dashboard.
      def self.update_settings(index)
        has_custom_settings = !Configurator.algolia('settings').nil?
        index_exists = index?(index.name)

        # No need to update the settings if the index is already configured and
        # the user did not specify custom settings
        return if index_exists && !has_custom_settings

        Logger.verbose('I:Updating settings')
        return if Configurator.dry_run?
        settings = Configurator.settings
        begin
          index.set_settings!(settings)
        rescue StandardError => error
          ErrorHandler.stop(error, settings: settings)
        end
      end

      # Public: Update records of the index
      #
      # index_name - The Algolia index
      # old_records_ids - Ids of records to delete from the index
      # new_records - Records to add to the index
      #
      # Note: All operations will be done in one batch, assuring an atomic
      # update
      # Does nothing in dry run mode
      def self.update_records(index_name, old_records_ids, new_records)
        # Stop if nothing to change
        if old_records_ids.empty? && new_records.empty?
          Logger.log('I:Nothing to index. Your content is already up to date.')
          return
        end

        Logger.log("I:Updating records in index #{index_name}...")
        Logger.log("I:Records to delete: #{old_records_ids.length}")
        Logger.log("I:Records to add:    #{new_records.length}")
        return if Configurator.dry_run?

        # We group delete and add operations into the same batch. Delete
        # operations should still come first, to avoid hitting an overquota too
        # soon
        operations = []
        old_records_ids.each do |object_id|
          operations << {
            action: 'deleteObject', indexName: index_name,
            body: { objectID: object_id }
          }
        end
        operations += new_records.map do |new_record|
          { action: 'addObject', indexName: index_name, body: new_record }
        end

        # Run the batches in slices if they are too large
        batch_size = Configurator.algolia('indexing_batch_size')
        operations.each_slice(batch_size) do |slice|
          begin
            ::Algolia.batch!(slice)
          rescue StandardError => error
            records = slice.map do |record|
              record[:body]
            end
            ErrorHandler.stop(error, records: records)
          end
        end
      end

      # Public: Push all records to Algolia and configure the index
      #
      # records - Records to push
      def self.run(records)
        init

        # Indexing zero record is surely a misconfiguration
        if records.length.zero?
          files_to_exclude = Configurator.algolia('files_to_exclude').join(', ')
          Logger.known_message(
            'no_records_found',
            'files_to_exclude' => files_to_exclude,
            'nodes_to_index' => Configurator.algolia('nodes_to_index')
          )
          exit 1
        end

        index_name = Configurator.index_name
        index = index(index_name)

        # Update settings
        update_settings(index)

        # Getting list of objectID in remote and locally
        remote_ids = remote_object_ids(index)
        local_ids = local_object_ids(records)

        # Getting list of what to add and what to delete
        old_records_ids = remote_ids - local_ids
        new_records_ids = local_ids - remote_ids
        new_records = records.select do |record|
          new_records_ids.include?(record[:objectID])
        end
        update_records(index_name, old_records_ids, new_records)

        Logger.log('I:✔ Indexing complete')
      end
    end
  end
end
