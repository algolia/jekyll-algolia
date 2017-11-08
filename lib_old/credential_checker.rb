require 'algoliasearch'
require 'nokogiri'
require 'json'
require_relative './error_handler.rb'

# Will check that all the needed credentials are correctly given by the user
# before starting any push process
class AlgoliaSearchCredentialChecker
  attr_accessor :config, :logger

  def initialize(config)
    @config = config
    @logger = AlgoliaSearchErrorHandler.new
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

  # Read key either from ENV or _config.yml
  def get_key(env_name, config_key)
    # First read in ENV
    return ENV[env_name] if ENV[env_name]

    # Otherwise read from _config.yml
    if @config['algolia'] && @config['algolia'][config_key]
      return @config['algolia'][config_key]
    end

    nil
  end

  # Read the application id either from the config file or from ENV
  def application_id
    get_key('ALGOLIA_APPLICATION_ID', 'application_id')
  end

  # Read the index name either from the config file or from ENV
  def index_name
    get_key('ALGOLIA_INDEX_NAME', 'index_name')
  end

  # Check that the API key is available
  def check_api_key
    return if api_key
    @logger.display('api_key_missing')
    exit 1
  end

  # Check that the application id is defined
  def check_application_id
    return if application_id
    @logger.display('application_id_missing')
    exit 1
  end

  # Check that the index name is defined
  def check_index_name
    return if index_name
    @logger.display('index_name_missing')
    exit 1
  end

  # Check that all credentials are present
  # Stop with a helpful message if not
  def assert_valid
    check_api_key
    check_application_id
    check_index_name

    Algolia.init(
      application_id: application_id,
      api_key: api_key
    )

    nil
  end
end
