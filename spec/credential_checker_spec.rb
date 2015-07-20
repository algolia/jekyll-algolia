require 'spec_helper'

describe(AlgoliaSearchCredentialChecker) do
  let(:config) do
    {
      'source' => File.expand_path('./spec/fixtures'),
      'markdown_ext' => 'md,mkd',
      'algolia' => {
        'application_id' => 'APPID',
        'index_name' => 'INDEXNAME'
      }
    }
  end
  let(:checker) { AlgoliaSearchCredentialChecker.new(config) }

  describe 'api_key' do
    it 'returns nil if no key found' do
      # Given

      # When
      actual = checker.api_key

      # Then
      expect(actual).to be_nil
    end

    it 'reads from ENV var if set' do
      # Given
      stub_const('ENV', 'ALGOLIA_API_KEY' => 'APIKEY_FROM_ENV')

      # When
      actual = checker.api_key

      # Then
      expect(actual).to eq 'APIKEY_FROM_ENV'
    end

    it 'reads from _algolia_api_key in source if set' do
      # Given
      checker.config['source'] = File.join(config['source'], 'api_key_dir')

      # When
      actual = checker.api_key

      # Then
      expect(actual).to eq 'APIKEY_FROM_FILE'
    end

    it 'reads from ENV before from file' do
      # Given
      checker.config['source'] = File.join(config['source'], 'api_key_dir')
      stub_const('ENV', 'ALGOLIA_API_KEY' => 'APIKEY_FROM_ENV')

      # When
      actual = checker.api_key

      # Then
      expect(actual).to eq 'APIKEY_FROM_ENV'
    end
  end

  describe 'assert_valid' do
    it 'should display error if no api key' do
      # Given
      allow(checker).to receive(:api_key) { nil }

      # Then
      expect(Jekyll.logger).to receive(:error).with(/api key/i)
      expect(Jekyll.logger).to receive(:warn).at_least(:once)
      expect(-> { checker.assert_valid }).to raise_error SystemExit
    end

    it 'should display error if no application id' do
      # Given
      checker.config['algolia'] = {
        'application_id' => nil,
        'index_name' => 'INDEX_NAME'
      }
      stub_const('ENV', 'ALGOLIA_API_KEY' => 'APIKEY_FROM_ENV')

      # Then
      expect(Jekyll.logger).to receive(:error).with(/application id/i)
      expect(Jekyll.logger).to receive(:warn).at_least(:once)
      expect(-> { checker.assert_valid }).to raise_error SystemExit
    end

    it 'should display error if no index name' do
      # Given
      checker.config['algolia'] = {
        'application_id' => 'APPLICATION_ID',
        'index_name' => nil
      }
      stub_const('ENV', 'ALGOLIA_API_KEY' => 'APIKEY_FROM_ENV')

      # Then
      expect(Jekyll.logger).to receive(:error).with(/index name/i)
      expect(Jekyll.logger).to receive(:warn).at_least(:once)
      expect(-> { checker.assert_valid }).to raise_error SystemExit
    end

    it 'should init the Algolia client' do
      # Given
      stub_const('ENV', 'ALGOLIA_API_KEY' => 'APIKEY_FROM_ENV')
      allow(Algolia).to receive(:init)

      # When
      checker.assert_valid

      # Then
      expect(Algolia).to have_received(:init).with(
        application_id: 'APPID',
        api_key: 'APIKEY_FROM_ENV'
      )
    end
  end
end
