require 'algoliasearch'
require 'nokogiri'
require 'json'

# Given an HTML file as input, will return an array of records to index
class AlgoliaSearchCredentialChecker
  attr_accessor :config

  def initialize(config)
    @config = config
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

  # Check that the API key is available
  def check_api_key
    return if api_key
    Jekyll.logger.error 'Algolia Error: No API key defined'
    Jekyll.logger.warn '  You have two ways to configure your API key:'
    Jekyll.logger.warn '    - The ALGOLIA_API_KEY environment variable'
    Jekyll.logger.warn '    - A file named ./_algolia_api_key in your '\
      'source folder'
    exit 1
  end

  # Check that the application id is defined
  def check_application_id
    return if @config['algolia'] && @config['algolia']['application_id']
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

  # Check that the index name is defined
  def check_index_name
    return if @config['algolia'] && @config['algolia']['index_name']
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

  # Check that all credentials are present
  # Stop with a helpful message if not
  def assert_valid
    check_api_key
    check_application_id
    check_index_name

    Algolia.init(
      application_id: @config['algolia']['application_id'],
      api_key: api_key
    )

    nil
  end
end
