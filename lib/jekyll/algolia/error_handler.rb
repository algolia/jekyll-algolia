require 'verbal_expressions'
require 'filesize'

module Jekyll
  module Algolia
    # Catch API errors and display messages
    module ErrorHandler
      include Jekyll::Algolia

      def self.stop(error, context = {})
        error_details = identify(error, context)

        if error_details == false
          Logger.log("E:#{error}")
        else
          Logger.log("E:#{error_details}")
        end

        exit 1
      end

      def self.identify(error, context = {})
        known_errors = %w[
          unknown_application_id
          invalid_credentials_for_tmp_index
          invalid_credentials
          record_too_big
        ]

        # Checking the errors against our known list
        known_errors.each do |potential_error|
          error_check = send("#{potential_error}?", error, context)
          next if error_check == false
          return {
            name: potential_error,
            details: error_check
          }
        end
        false
      end

      def self.error_hash(message)
        message = message.delete("\n")

        # Ex: Cannot PUT to https://appid.algolia.net/1/indexes/index_name/settings:
        # {"message":"Invalid Application-ID or API key","status":403} (403)
        regex = VerEx.new do
          find 'Cannot '
          capture('verb') { word }
          find ' to '
          capture('scheme') { word }
          find '://'
          capture('application_id') { word }
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

        matches = regex.match(message)
        return false unless matches

        # Convert matches to a hash
        hash = {}
        matches.names.each do |name|
          hash[name] = matches[name]
        end

        hash['api_version'] = hash['api_version'].to_i
        hash['http_error'] = hash['http_error'].to_i
        hash['json'] = JSON.parse(hash['json'])
        hash
      end

      def self.unknown_application_id?(error, _context = {})
        message = error.message
        return false if message !~ /^Cannot reach any host/

        matches = /.*\((.*)\.algolia.net.*/.match(message)

        { 'application_id' => matches[1] }
      end

      def self.invalid_credentials_for_tmp_index?(error, _context = {})
        return false unless invalid_credentials?(error)

        details = error_hash(error.message)

        return false if details['index_name'] !~ /_tmp$/

        {
          'application_id' => details['application_id'],
          'index_name' => Configurator.index_name,
          'index_name_tmp' => details['index_name']
        }
      end

      def self.invalid_credentials?(error, _context = {})
        details = error_hash(error.message)

        if details['json']['message'] != 'Invalid Application-ID or API key'
          return false
        end

        {
          'application_id' => details['application_id'],
          'index_name' => Configurator.index_name
        }
      end

      def self.record_too_big?(error, context = {})
        details = error_hash(error.message)

        message = details['json']['message']
        return false if message !~ /^Record .* is too big .*/

        # Getting the record size
        size, = /.*size=(.*) bytes.*/.match(message).captures
        size = Filesize.from("#{size} B").pretty
        object_id = details['json']['objectID']

        # Getting record details
        record = Utils.find_by_key(context[:records], :objectID, object_id)

        {
          'object_id' => object_id,
          'object_title' => record[:title],
          'object_url' => record[:url],
          'object_hint' => record[:text][0..100],
          'size' => size,
          'size_limit' => '10 Kb'
        }
      end
    end
  end
end
