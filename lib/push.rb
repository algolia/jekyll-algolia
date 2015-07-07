require 'algoliasearch'
require 'nokogiri'
require 'json'
require_relative './record_extractor.rb'

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

      # Allow for passing index name on the command line
      index_name = args[0]
      @config['algolia']['index_name'] = index_name if index_name
      self
    end

    # Check if the specified file should be indexed (we exclude static files,
    # robots.txt and custom defined exclusions).
    def indexable?(file)
      return false if file.is_a?(Jekyll::StaticFile)

      # Keep only markdown and html files
      allowed_extensions = %w(html)
      if @config['markdown_ext']
        allowed_extensions += @config['markdown_ext'].split(',')
      end
      current_extension = File.extname(file.name)[1..-1]
      return false unless allowed_extensions.include?(current_extension)

      # Exclude files manually excluded from config
      excluded_files = @config['algolia']['excluded_files']
      unless excluded_files.nil?
        return false if excluded_files.include?(file.name)
      end

      true
    end

    # Run the default `jekyll build` command but overwrite the actual "write
    # files on disk" part to instead push data to Algolia
    def process
      site = Jekyll::Site.new(@config)

      def site.write
        items = []
        each_site_file do |file|
          next unless AlgoliaSearchJekyllPush.indexable?(file)

          new_items = AlgoliaSearchRecordExtractor.new(file).extract
          next if new_items.nil?
          items += new_items
        end
        AlgoliaSearchJekyllPush.push(items)
      end

      # This will call the build command by default, which will in turn call our
      # custom .write method
      site.process
    end

    # Read the API key either from ENV or from an _algolia_api_key file in
    # source folder
    def api_key
      # First read in ENV
      return ENV['ALGOLIA_API_KEY'] if ENV['ALGOLIA_API_KEY']

      # Otherwise from file in source directory
      key_file = File.join(@config['source'], '_algolia_api_key')
      if File.exist?(key_file) && File.size(key_file) > 0
        return File.open(key_file).read.strip
      end
      nil
    end

    # Check that all credentials are present, and stop with a helpfull message
    # if not
    def check_credentials
      unless api_key
        Jekyll.logger.error 'Algolia Error: No API key defined'
        Jekyll.logger.warn '  You have two ways to configure your API key:'
        Jekyll.logger.warn '    - The ALGOLIA_API_KEY environment variable'
        Jekyll.logger.warn '    - A file named ./_algolia_api_key in your '\
                           'source folder'
        exit 1
      end

      unless @config['algolia'] && @config['algolia']['application_id']
        Jekyll.logger.error 'Algolia Error: No application ID defined'
        Jekyll.logger.warn '  Please set your application id in the '\
                           '_config.yml file, like so:'
        Jekyll.logger.warn ''
        # The spaces are needed otherwise the text is centered
        Jekyll.logger.warn '  algolia:         '
        Jekyll.logger.warn '    application_id: \'{your_application_id}\''
        Jekyll.logger.warn ''
        Jekyll.logger.warn '  Your application ID can be found in your algolia'\
                           ' dashboard'
        Jekyll.logger.warn '    https://www.algolia.com/licensing'
        exit 1
      end

      unless @config['algolia']['index_name']
        Jekyll.logger.error 'Algolia Error: No index name defined'
        Jekyll.logger.warn '  Please set your index name in the _config.yml'\
                           ' file, like so:'
        Jekyll.logger.warn ''
        # The spaces are needed otherwise the text is centered
        Jekyll.logger.warn '  algolia:         '
        Jekyll.logger.warn '    index_name: \'{your_index_name}\''
        Jekyll.logger.warn ''
        Jekyll.logger.warn '  You can edit your indices in your dashboard'
        Jekyll.logger.warn '    https://www.algolia.com/explorer'
        exit 1
      end
      true
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
        customRanking: ['desc(posted_at)', 'desc(title_weight)'],
        highlightPreTag: '<span class="algolia__result-highlight">',
        highlightPostTag: '</span>'
      }

      # Merge default settings with user custom ones
      if @config['algolia'].key?('settings')
        custom_settings = {}
        @config['algolia']['settings'].each do |key, value|
          custom_settings[key.to_sym] = value
        end
        settings.merge!(custom_settings)
      end

      index.set_settings(settings)
    end

    def push(items)
      check_credentials

      index_name = @config['algolia']['index_name']
      Algolia.init(
        application_id: @config['algolia']['application_id'],
        api_key: api_key
      )
      index = Algolia::Index.new(index_name)
      configure_index(index)
      index.clear_index

      items.each_slice(1000) do |batch|
        Jekyll.logger.info "Indexing #{batch.size} items"
        begin
          index.add_objects(batch)
        rescue StandardError => error
          Jekyll.logger.error 'Algolia Error: HTTP Error'
          Jekyll.logger.warn error.message
          exit 1
        end
      end

      Jekyll.logger.info "Indexing of #{items.size} items " \
                         "in #{index_name} done."
    end
  end
end
