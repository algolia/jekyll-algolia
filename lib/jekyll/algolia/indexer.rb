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

      # Public: Update records of the specified index
      #
      # index - Algolia Index to update
      # records - Array of records to update
      #
      # New records will be automatically added. Technically existing records
      # should be updated but this case should never happen as changing a record
      # content will change its objectID as well.
      #
      # Does nothing in dry run mode
      def self.update_records(index, records)
        batch_size = Configurator.algolia('indexing_batch_size')
        records.each_slice(batch_size) do |batch|
          Logger.log("I:Pushing #{batch.size} records")
          next if Configurator.dry_run?
          begin
            index.add_objects!(batch)
          rescue StandardError => error
            ErrorHandler.stop(error, records: records)
          end
        end
      end

      # Public: Delete records whose objectIDs are passed
      #
      # index - Algolia Index to target
      # ids - Array of objectIDs to delete
      #
      # Does nothing in dry run mode
      def self.delete_records_by_id(index, ids)
        return if ids.empty?
        Logger.log("I:Deleting #{ids.length} records")
        return if Configurator.dry_run?

        begin
          index.delete_objects!(ids)
        rescue StandardError => error
          ErrorHandler.stop(error)
        end
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
      # settings - The hash of settings to pass to the index
      #
      # Does nothing in dry run mode
      def self.update_settings(index, settings)
        Logger.verbose('I:Updating settings')
        return if Configurator.dry_run?
        begin
          index.set_settings!(settings)
        rescue StandardError => error
          ErrorHandler.stop(error, settings: settings)
        end
      end

      # Public: Index content following the `diff` indexing mode
      #
      # records - Array of local records
      #
      # The `diff` indexing mode will only push new content to the index and
      # remove old content from it. It won't touch records that haven't been
      # updated. It will be a bit slower as it will first need to get the list
      # of all records in the index, but it will consume less operations.
      def self.run_diff_mode(records)
        index = index(Configurator.index_name)

        # Update settings
        update_settings(index, Configurator.settings)

        # Getting list of objectID in remote and locally
        remote_ids = remote_object_ids(index)
        local_ids = local_object_ids(records)

        old_records_ids = remote_ids - local_ids
        new_records_ids = local_ids - remote_ids
        if old_records_ids.empty? && new_records_ids.empty?
          Logger.log('I:Nothing to index. Your content is already up to date.')
          return
        end

        Logger.log("I:Updating records in index #{index.name}...")

        # Delete remote records that are no longer available locally
        delete_records_by_id(index, old_records_ids)

        # Add only records that are not yet already in the remote
        new_records = records.select do |record|
          new_records_ids.include?(record[:objectID])
        end
        update_records(index, new_records)

        Logger.log('I:✔ Indexing complete')
      end

      # Public: Get the settings of the remote index
      #
      # index - The Algolia Index
      def self.remote_settings(index)
        index.get_settings
      rescue StandardError => error
        ErrorHandler.stop(error)
      end

      # Public: Rename an index
      #
      # old_name - Current name of the index
      # new_name - New name of the index
      #
      # Does nothing in dry run mode
      def self.rename_index(old_name, new_name)
        Logger.verbose("I:Renaming `#{old_name}` to `#{new_name}`")
        return if Configurator.dry_run?
        begin
          ::Algolia.move_index!(old_name, new_name)
        rescue StandardError => error
          ErrorHandler.stop(error, new_name: new_name)
        end
      end

      # Public: Copy an index
      #
      # old_name - Current name of the index
      # new_name - New name of the index
      #
      # Does nothing in dry run mode
      def self.copy_index(old_name, new_name)
        Logger.verbose("I:Copying `#{old_name}` to `#{new_name}`")
        return if Configurator.dry_run?
        begin
          ::Algolia.copy_index!(old_name, new_name)
        rescue StandardError => error
          ErrorHandler.stop(error, new_name: new_name)
        end
      end

      # Public: Index content following the `atomic` indexing mode
      #
      # records - Array of records to push
      #
      # The `atomic` will first create an hidden copy of the current index.
      # It will then update this copy following the same logic as the `diff`
      # mode, deleting old records and adding new ones. Once finished, it will
      # overwrite the current index with this hidden one.
      def self.run_atomic_mode(records)
        index_name = Configurator.index_name
        index = index(index_name)
        index_tmp_name = "#{Configurator.index_name}_tmp"
        index_tmp = index(index_tmp_name)

        # Getting list of objectID in remote and locally
        remote_ids = remote_object_ids(index)
        local_ids = local_object_ids(records)

        old_records_ids = remote_ids - local_ids
        new_records_ids = local_ids - remote_ids
        if old_records_ids.empty? && new_records_ids.empty?
          Logger.log('I:Nothing to index. Your content is already up to date.')
          return
        end

        # Copying original index to temporary one
        Logger.verbose("I:Using `#{index_tmp_name}` as temporary index")
        copy_index(index_name, index_tmp_name)

        # Update settings
        Logger.verbose("I:Updating `#{index_tmp_name}` settings")
        update_settings(index_tmp, Configurator.settings)

        Logger.log("I:Updating records in index #{index_tmp_name}...")

        # Delete remote records that are no longer available locally
        delete_records_by_id(index_tmp, old_records_ids)

        # Add only records that are not yet already in the remote
        new_records = records.select do |record|
          new_records_ids.include?(record[:objectID])
        end
        update_records(index_tmp, new_records)

        # Renaming the new index in place of the old
        Logger.verbose("I:Overwriting `#{index_name}` with `#{index_tmp_name}`")
        rename_index(index_tmp_name, index_name)

        Logger.log('I:✔ Indexing complete')
      end

      # Public: Push all records to Algolia and configure the index
      #
      # records - Records to push
      def self.run(records)
        init

        record_count = records.length

        # Indexing zero record is surely a misconfiguration
        if record_count.zero?
          files_to_exclude = Configurator.algolia('files_to_exclude').join(', ')
          Logger.known_message(
            'no_records_found',
            'files_to_exclude' => files_to_exclude,
            'nodes_to_index' => Configurator.algolia('nodes_to_index')
          )
          exit 1
        end

        indexing_mode = Configurator.indexing_mode
        Logger.verbose("I:Indexing mode: #{indexing_mode}")
        send("run_#{indexing_mode}_mode".to_sym, records)
      end
    end
  end
end
