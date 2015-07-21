require 'algoliasearch'
require 'nokogiri'
require 'json'
require_relative './record_extractor.rb'
require_relative './credential_checker.rb'

# `jekyll algolia push` command
class AlgoliaSearchJekyllPush < Jekyll::Command
  class << self
    attr_accessor :options, :config

    def init_with_program(_prog)
    end

    # Init the command with options passed on the command line
    # `jekyll algolia push ARG1 ARG2 --OPTION_NAME1 OPTION_VALUE1`
    # config comes from _config.yml
    def init_options(args = [], options = {}, config = {})
      args = [] unless args
      @args = args
      @options = options
      @config = config
      @is_verbose = @config['verbose']

      self
    end

    # Check if the specified file should be indexed (we exclude static files,
    # robots.txt and custom defined exclusions).
    def indexable?(file)
      return false if file.is_a?(Jekyll::StaticFile)

      basename = File.basename(file.path)
      extname = File.extname(basename)[1..-1]

      # Keep only markdown and html files
      allowed_extensions = %w(html)
      if @config['markdown_ext']
        allowed_extensions += @config['markdown_ext'].split(',')
      end
      return false unless allowed_extensions.include?(extname)

      return false if excluded_file?(file.path)

      true
    end

    # Check if the file is in the list of excluded files
    def excluded_file?(filepath)
      excluded = [
        %r{^page([0-9]*)/index\.html}
      ]
      if @config['algolia']
        excluded += (@config['algolia']['excluded_files'] || [])
      end

      excluded.each do |pattern|
        pattern = /#{Regexp.quote(pattern)}/ if pattern.is_a? String
        return true if filepath =~ pattern
      end
      false
    end

    # Return a patched version of a Jekyll instance
    def jekyll_new(config)
      site = Jekyll::Site.new(config)

      # Patched version of `write` that will push to Algolia instead of writing
      # on disk
      def site.write
        items = []
        is_verbose = config['verbose']
        each_site_file do |file|
          next unless AlgoliaSearchJekyllPush.indexable?(file)
          Jekyll.logger.info "Extracting data from #{file.path}" if is_verbose
          new_items = AlgoliaSearchRecordExtractor.new(file).extract
          next if new_items.nil?

          items += new_items
        end
        AlgoliaSearchJekyllPush.push(items)
      end

      site
    end

    # Get index settings
    def configure_index(index)
      settings = {
        distinct: true,
        attributeForDistinct: 'title',
        attributesForFaceting: %w(tags type title),
        attributesToIndex: %w(
          title h1 h2 h3 h4 h5 h6
          unordered(text)
          unordered(tags)
        ),
        attributesToRetrieve: %w(
          title h1 h2 h3 h4 h5 h6
          url
          tag_name
          raw_html
          text
          posted_at
          css_selector
          css_selector_parent
        ),
        customRanking: ['desc(posted_at)', 'desc(weight)'],
        highlightPreTag: '<span class="algolia__result-highlight">',
        highlightPostTag: '</span>'
      }

      # Merge default settings with user custom ones
      if @config['algolia']
        (@config['algolia']['settings'] || []).each do |key, value|
          settings[key.to_sym] = value
        end
      end

      index.set_settings(settings)
    end

    def push(items)
      AlgoliaSearchCredentialChecker.new(@config).assert_valid

      is_dry_run = @config['dry_run']
      Jekyll.logger.info '=== DRY RUN ===' if is_dry_run

      # Create a temporary index
      index_name = @config['algolia']['index_name']
      index_name_tmp = "#{index_name}_tmp"
      index_tmp = Algolia::Index.new(index_name_tmp)
      configure_index(index_tmp) unless is_dry_run

      # Push to temporary index
      items.each_slice(1000) do |batch|
        Jekyll.logger.info "Indexing #{batch.size} items"
        begin
          index_tmp.add_objects!(batch) unless is_dry_run
        rescue StandardError => error
          Jekyll.logger.error 'Algolia Error: HTTP Error'
          Jekyll.logger.warn error.message
          exit 1
        end
      end

      # Move temporary index to real one
      Algolia.move_index(index_name_tmp, index_name) unless is_dry_run

      Jekyll.logger.info "Indexing of #{items.size} items " \
                         "in #{index_name} done."
    end
  end
end
