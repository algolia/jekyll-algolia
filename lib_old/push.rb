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


    # Get index settings
    def configure_index(index)
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

  end
end
