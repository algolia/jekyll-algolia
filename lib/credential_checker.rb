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

  def display_error(file)
    file = File.expand_path(File.join(File.dirname(__FILE__), '../txt', file))
    content = File.open(file).readlines.map(&:chomp)
    content.each_with_index do |line, index|
      if index == 0
        Jekyll.logger.error line
        next
      end
      Jekyll.logger.warn line
    end
  end

  # Check that the API key is available
  def check_api_key
    return if api_key
    display_error('api_key_missing')
    exit 1
  end

  # Check that the application id is defined
  def check_application_id
    return if @config['algolia'] && @config['algolia']['application_id']
    display_error('application_id_missing')
    exit 1
  end

  # Check that the index name is defined
  def check_index_name
    return if @config['algolia'] && @config['algolia']['index_name']
    display_error('index_name_missing')
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
