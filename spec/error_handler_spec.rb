require 'spec_helper'

describe(AlgoliaSearchErrorHandler) do
  before(:each) do
    @error_handler = AlgoliaSearchErrorHandler.new
  end

  describe 'display' do
    before(:each) do
      allow(Jekyll.logger).to receive(:error)
      allow(Jekyll.logger).to receive(:warn)
    end

    it 'should display first line as error' do
      # Given
      input = 'sample'

      # When
      @error_handler.display(input)

      # Then
      expect(Jekyll.logger).to have_received(:error).exactly(1).times
    end

    it 'should display all other lines as warnings' do
      # Given
      input = 'sample'

      # When
      @error_handler.display(input)

      # Then
      expect(Jekyll.logger).to have_received(:warn).exactly(3).times
    end
  end

  describe 'parse_algolia_error' do
    before(:each) do
      @algolia_error = 'Cannot PUT to ' \
        'https://appid.algolia.net/1/indexes/index_name/settings: ' \
        '{"message":"Invalid Application-ID or API key","status":403} (403)'
    end

    it 'should extract all the url parts' do
      # Given
      input = @algolia_error

      # When
      actual = @error_handler.parse_algolia_error(input)

      # Then
      expect(actual['verb']).to eq 'PUT'
      expect(actual['scheme']).to eq 'https'
      expect(actual['app_id']).to eq 'appid'
      expect(actual['api_section']).to eq 'indexes'
      expect(actual['index_name']).to eq 'index_name'
      expect(actual['api_action']).to eq 'settings'
    end

    it 'should cast integers to integers' do
      # Given
      input = @algolia_error

      # When
      actual = @error_handler.parse_algolia_error(input)

      # Then
      expect(actual['api_version']).to eq 1
      expect(actual['http_error']).to eq 403
    end

    it 'should parse the JSON part' do
      # Given
      input = @algolia_error

      # When
      actual = @error_handler.parse_algolia_error(input)

      # Then
      expect(actual['json']).to be_a(Hash)
      expect(actual['json']['status']).to eq 403
    end

    it 'should return false if this is not parsable' do
      # Given
      input = 'foo bar baz'

      # When
      actual = @error_handler.parse_algolia_error(input)

      # Then
      expect(actual).to eq(false)
    end

    it 'should work on multiline errors' do
      # Given
      input = @algolia_error.gsub('}', "}\n")

      # When
      actual = @error_handler.parse_algolia_error(input)

      # Then
      expect(actual).to be_a(Hash)
      expect(actual['http_error']).to eq 403
    end
  end

  describe 'readable_algolia_error' do
    it 'should warn about key ACL' do
      # Given
      parsed = {
        'http_error' => 403,
        'index_name' => 'something_tmp'
      }
      allow(@error_handler).to receive(:parse_algolia_error).and_return(parsed)

      # When
      actual = @error_handler.readable_algolia_error('error')

      # Then
      expect(actual).to eq('check_key_acl_to_tmp_index')
    end

    it 'should return false if no nice message found' do
      # Given
      parsed = false
      allow(@error_handler).to receive(:parse_algolia_error).and_return(parsed)

      # When
      actual = @error_handler.readable_algolia_error('error')

      # Then
      expect(actual).to eq(false)
    end

    it 'should return false if message does not match any known case' do
      # Given
      parsed = {
        'http_error' => 42
      }
      allow(@error_handler).to receive(:parse_algolia_error).and_return(parsed)

      # When
      actual = @error_handler.readable_algolia_error('error')

      # Then
      expect(actual).to eq(false)
    end
  end
end
