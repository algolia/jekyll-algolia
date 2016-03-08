require 'json'
require 'verbal_expressions'

# Helps in displaying useful error messages to users, to help them debug their
# issues
class AlgoliaSearchErrorHandler
  # Will output the specified error file.
  # First line is displayed as error, next ones as warning
  def display(file)
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

  def error_tester
    # Ex: Cannot PUT to https://appid.algolia.net/1/indexes/index_name/settings:
    # {"message":"Invalid Application-ID or API key","status":403} (403)
    VerEx.new do
      find 'Cannot '
      capture('verb') { word }
      find ' to '
      capture('scheme') { word }
      find '://'
      capture('app_id') { word }
      anything_but '/'
      find '/'
      capture('api_version') { digit }
      find '/'
      capture('api_section') { word }
      find '/'
      capture('index_name') { word }
      find '/'
      capture('api_action') { word }
      find ': '
      capture('json') do
        find '{'
        anything_but('}')
        find '}'
      end
      find ' ('
      capture('http_error') { word }
      find ')'
    end
  end

  def parse_algolia_error(error)
    error.delete!("\n")

    tester = error_tester
    matches = tester.match(error)

    return false unless matches

    hash = {}
    matches.names.each do |match|
      hash[match] = matches[match]
    end

    # Cast integers
    hash['api_version'] = hash['api_version'].to_i
    hash['http_error'] = hash['http_error'].to_i

    # Parse JSON
    hash['json'] = JSON.parse(hash['json'])

    hash
  end

  # Given an Algolia API error message, will return the best error message
  def readable_algolia_error(error)
    error = parse_algolia_error(error)
    return false unless error

    # Given API key does not have rights on the _tmp index
    if error['http_error'] == 403 && error['index_name'] =~ /_tmp$/
      return 'check_key_acl_to_tmp_index'
    end

    false
  end
end
