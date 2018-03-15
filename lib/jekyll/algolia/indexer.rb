# frozen_string_literal: true

require 'algoliasearch'
require 'yaml'
require 'algolia_html_extractor'

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
        @index = ::Algolia::Index.new(Configurator.index_name)

        set_user_agent

        self
      end

      # Public: Returns the Algolia index object
      def self.index
        @index
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

      # Public: Returns an array of all the objectIDs in the index
      #
      # The returned array is sorted. It won't have any impact on the way it is
      # processed, but makes debugging easier when comparing arrays is needed.
      def self.remote_object_ids
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

      # Public: Update records of the index
      #
      # old_records_ids - Ids of records to delete from the index
      # new_records - Records to add to the index
      #
      # Note: All operations will be done in one batch, assuring an atomic
      # update
      # Does nothing in dry run mode
      def self.update_records(old_records_ids, new_records)
        # Stop if nothing to change
        if old_records_ids.empty? && new_records.empty?
          Logger.log('I:Content is already up to date.')
          return
        end

        Logger.log("I:Updating records in index #{index.name}...")
        Logger.log("I:Records to delete: #{old_records_ids.length}")
        Logger.log("I:Records to add:    #{new_records.length}")
        return if Configurator.dry_run?

        # We group delete and add operations into the same batch. Delete
        # operations should still come first, to avoid hitting an overquota too
        # soon
        operations = []
        old_records_ids.each do |object_id|
          operations << {
            action: 'deleteObject', indexName: index.name,
            body: { objectID: object_id }
          }
        end
        operations += new_records.map do |new_record|
          { action: 'addObject', indexName: index.name, body: new_record }
        end

        # Run the batches in slices if they are too large
        batch_size = Configurator.algolia('indexing_batch_size')
        slices = operations.each_slice(batch_size).to_a

        should_have_progress_bar = (slices.length > 1)
        if should_have_progress_bar
          progress_bar = ProgressBar.create(
            total: slices.length,
            format: 'Pushing records (%j%%) |%B|'
          )
        end

        slices.each do |slice|
          begin
            ::Algolia.batch!(slice)

            progress_bar.increment if should_have_progress_bar
          rescue StandardError => error
            records = slice.map do |record|
              record[:body]
            end
            ErrorHandler.stop(error, records: records)
          end
        end
      end

      # Public: Get a unique settingID for the current settings
      #
      # The settingID is generated as a hash of the current settings. As it will
      # be stored in the userData key of the resulting config, we exclude that
      # key from the hashing.
      def self.local_setting_id
        settings = Configurator.settings
        settings.delete('userData')
        AlgoliaHTMLExtractor.uuid(settings)
      end

      # Public: Get the settings of the remote index
      #
      # In case the index is not accessible, it will return nil
      def self.remote_settings
        index.get_settings
      rescue StandardError
        nil
      end

      # Public: Smart update of the settings of the index
      #
      # This will first compare the settings about to be pushed with the
      # settings already pushed. It will compare userData.settingID for that.
      # If the settingID is the same, we don't push as this won't change
      # anything. We will still check if the remote config seem to have been
      # manually altered though, and warn the user that this is not the
      # preferred way of doing so.
      #
      # If the settingID are not matching, it means our config is different, so
      # we push it, overriding the settingID for next push.
      def self.update_settings
        current_remote_settings = remote_settings || {}
        remote_setting_id = current_remote_settings.dig('userData', 'settingID')

        settings = Configurator.settings
        setting_id = local_setting_id

        are_settings_forced = Configurator.force_settings?

        # The config we're about to push is the same we pushed previously. We
        # won't push again.
        if setting_id == remote_setting_id && !are_settings_forced
          Logger.log('I:Settings are already up to date.')
          # Check if remote config has been changed outside of the plugin, so we
          # can warn users that they should not alter their config from outside
          # of the plugin.
          current_remote_settings.delete('userData')
          changed_keys = Utils.diff_keys(settings, current_remote_settings)
          unless changed_keys.nil?
            warn_of_manual_dashboard_editing(changed_keys)
          end

          return
        end

        # Settings have changed, we push them
        settings['userData'] = {
          'settingID' => setting_id,
          'pluginVersion' => VERSION
        }

        Logger.log("I:Updating settings of index #{index.name}")
        return if Configurator.dry_run?
        set_settings(settings)
      end

      # Public: Set new settings to an index
      #
      # Will dispatch to the error handler if it fails
      # rubocop:disable Naming/AccessorMethodName
      def self.set_settings(settings)
        index.set_settings!(settings)
      rescue StandardError => error
        ErrorHandler.stop(error, settings: settings)
      end
      # rubocop:enable Naming/AccessorMethodName

      # Public: Warn users that they have some settings manually configured in
      # their dashboard
      #
      # When users change some settings in their dashboard, those settings might
      # get overwritten by the pluging. We can't prevent that, but we can warn
      # them when we detect they changed something.
      def self.warn_of_manual_dashboard_editing(changed_keys)
        # Transform the hash into readable YAML
        yaml_lines = changed_keys
                     .to_yaml(indentation: 2)
                     .split("\n")[1..-1]
        yaml_lines.map! do |line|
          line = line.gsub(/^ */) { |spaces| ' ' * spaces.length }
          line = line.gsub('- ', '  - ')
          "W:    #{line}"
        end
        Logger.known_message(
          'settings_manually_edited',
          settings: yaml_lines.join("\n")
        )
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

        # Update settings
        update_settings

        # Getting list of objectID in remote and locally
        remote_ids = remote_object_ids
        local_ids = local_object_ids(records)

        # Getting list of what to add and what to delete
        old_records_ids = remote_ids - local_ids
        new_records_ids = local_ids - remote_ids
        new_records = records.select do |record|
          new_records_ids.include?(record[:objectID])
        end
        update_records(old_records_ids, new_records)

        Logger.log('I:✔ Indexing complete')
      end
    end
  end
end
