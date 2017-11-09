require 'algoliasearch'
require 'json'
require 'nokogiri'
require_relative './version'
require_relative './record_extractor'
require_relative './credential_checker'
require_relative './error_handler'

# `jekyll algolia push` main command
class AlgoliaSearchJekyllPush < Jekyll::Command
  class << self
    attr_accessor :options, :config

    def init_with_program(_prog)
    end


    # Check if the lazy update feature is enabled or not (default to false)
    def lazy_update?
      return false unless @config['algolia']
      return true if @config['algolia']['lazy_update']
      false
    end

    # Get index settings
    def configure_index(index)
      settings = {
        distinct: true,
        attributeForDistinct: 'url',
        attributesForFaceting: %w(tags type title),
        attributesToIndex: %w(
          title h1 h2 h3 h4 h5 h6
          unordered(text)
          unordered(tags)
        ),
        attributesToRetrieve: nil,
        customRanking: [
          'desc(posted_at)',
          'desc(weight.tag_name)',
          'asc(weight.position)'
        ],
        highlightPreTag: '<span class="algolia__result-highlight">',
        highlightPostTag: '</span>'
      }

      # Merge default settings with user custom ones
      if @config['algolia']
        (@config['algolia']['settings'] || []).each do |key, value|
          settings[key.to_sym] = value
        end
      end

      begin
        index.set_settings(settings)
      rescue StandardError => error
        display_error(error)
        exit 1
      end
    end

    # Display the error in a human-friendly way if possible
    def display_error(error)
      error_handler = AlgoliaSearchErrorHandler.new
      readable_error = error_handler.readable_algolia_error(error.message)

      if readable_error
        error_handler.display(readable_error)
      else
        Jekyll.logger.error 'Algolia Error: HTTP Error'
        Jekyll.logger.warn error.message
      end
    end

    # Change the User-Agent header to isolate calls from this plugin
    def set_user_agent_header
      plugin_version = AlgoliaSearchJekyllVersion.to_s
      client_version = AlgoliaSearchJekyllVersion.client
      ruby_version = AlgoliaSearchJekyllVersion.ruby
      jekyll_version = AlgoliaSearchJekyllVersion.jekyll

      user_agent = [
        "Jekyll Integration (#{plugin_version})",
        "Algolia for Ruby (#{client_version})",
        "Ruby (#{ruby_version})",
        "Jekyll (#{jekyll_version})"
      ].join('; ')

      Algolia.set_extra_header('User-Agent', user_agent)
    end

    # Create an index to push our data
    def create_index(index_name)
      set_user_agent_header
      index = Algolia::Index.new(index_name)
      configure_index(index) unless @is_dry_run
      index
    end

    # Push records to the index
    def batch_add_items(items, index)
      items.each_slice(1000) do |batch|
        Jekyll.logger.info "Indexing #{batch.size} items"
        begin
          index.add_objects!(batch) unless @is_dry_run
        rescue StandardError => error
          display_error(error)
          exit 1
        end
      end
    end

    # Greedy update will push all the records to a temporary index, then
    # override the existing index with this temp one
    def greedy_update(items)
      # Add items to a temp index, then rename it
      index_name = @checker.index_name
      index_name_tmp = "#{index_name}_tmp"
      batch_add_items(items, create_index(index_name_tmp))
      Algolia.move_index(index_name_tmp, index_name) unless @is_dry_run

      Jekyll.logger.info "Indexing of #{items.size} items " \
                         "in #{index_name} done."
    end

    # Lazy update will minimize the number of operations by only pushing new
    # data and deleting old data
    def lazy_update(items)
      index = create_index(@checker.index_name)
      remote = remote_ids(index)
      local = items.map { |item| item[:objectID] }

      delete_remote_not_in_local(index, local, remote)

      add_local_not_in_remote(index, items, local, remote)
    end

    # Array of all objectID in the remote index
    def remote_ids(index)
      list = []
      index.browse(attributesToRetrieve: 'objectID') do |hit|
        list << hit['objectID']
      end
      list
    end

    # Delete all remote items that are no longer in the local items
    def delete_remote_not_in_local(index, local, remote)
      list = remote - local
      Jekyll.logger.info "Deleting #{list.size} items"
      index.delete_objects!(list) unless list.empty?
    end

    # Push all local items that are not yet in the index
    def add_local_not_in_remote(index, items, local, remote)
      list = local - remote
      return Jekyll.logger.info "Adding #{list.size} items" if list.empty?
      items_to_push = items.select do |item|
        list.include?(item[:objectID])
      end
      batch_add_items(items_to_push, index)
    end

    def push(items)
      checker = AlgoliaSearchCredentialChecker.new(@config)
      checker.assert_valid

      Jekyll.logger.info '=== DRY RUN ===' if @is_dry_run

      @is_lazy_update ? lazy_update(items) : greedy_update(items)
    end
  end
end
