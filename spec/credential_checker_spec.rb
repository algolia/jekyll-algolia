require 'spec_helper'

describe(AlgoliaSearchCredentialChecker) do
  let(:config) do
    {
      'source' => fixture_path,
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

  describe 'check_api_key' do
    it 'should exit with error if no API key' do
      # Given
      allow(checker).to receive(:api_key).and_return(nil)
      allow(checker.logger).to receive(:display)

      # When / Then
      expect(-> { checker.check_api_key }).to raise_error SystemExit
    end

    it 'should do nothing when an API key is found' do
      # Given
      allow(checker).to receive(:api_key).and_return('APIKEY')

      # When / Then
      expect(-> { checker.check_api_key }).not_to raise_error
    end
  end

  describe 'application_id' do
    it 'reads value from the _config.yml file' do
      # Given

      # When
      actual = checker.application_id

      # Then
      expect(actual).to eq 'APPID'
    end

    it 'reads from ENV var if set' do
      # Given
      stub_const('ENV', 'ALGOLIA_APPLICATION_ID' => 'APPLICATION_ID_FROM_ENV')

      # When
      actual = checker.application_id

      # Then
      expect(actual).to eq 'APPLICATION_ID_FROM_ENV'
    end

    it 'returns nil if no key found' do
      # Given
      config['algolia']['application_id'] = nil

      # When
      actual = checker.application_id

      # Then
      expect(actual).to be_nil
    end
  end

  describe 'check_application_id' do
    it 'should exit with error if no application ID' do
      # Given
      allow(checker).to receive(:application_id).and_return(nil)
      allow(checker.logger).to receive(:display)

      # When / Then
      expect(-> { checker.check_application_id }).to raise_error SystemExit
    end

    it 'should do nothing when an application ID is found' do
      # Given
      allow(checker).to receive(:application_id).and_return('APPLICATIONID')

      # When / Then
      expect(-> { checker.check_application_id }).not_to raise_error
    end
  end

  describe 'index_name' do
    it 'reads value from the _config.yml file' do
      # Given

      # When
      actual = checker.index_name

      # Then
      expect(actual).to eq 'INDEXNAME'
    end

    it 'reads from ENV var if set' do
      # Given
      stub_const('ENV', 'ALGOLIA_INDEX_NAME' => 'INDEX_NAME_FROM_ENV')

      # When
      actual = checker.index_name

      # Then
      expect(actual).to eq 'INDEX_NAME_FROM_ENV'
    end

    it 'returns nil if no key found' do
      # Given
      config['algolia']['index_name'] = nil

      # When
      actual = checker.index_name

      # Then
      expect(actual).to be_nil
    end
  end
  describe 'check_index_name' do
    it 'should exit with error if no index name' do
      # Given
      allow(checker).to receive(:index_name).and_return(nil)
      allow(checker.logger).to receive(:display)

      # When / Then
      expect(-> { checker.check_index_name }).to raise_error SystemExit
    end

    it 'should do nothing when an index name is found' do
      # Given
      allow(checker).to receive(:index_name).and_return('INDEXNAME')

      # When / Then
      expect(-> { checker.check_index_name }).not_to raise_error
    end
  end

  describe 'assert_valid' do
    before(:each) do
      allow(checker.logger).to receive(:display)
    end
    it 'should display error if no api key' do
      # Given
      allow(checker).to receive(:api_key).and_return nil

      # Then
      expect(-> { checker.assert_valid }).to raise_error SystemExit
      expect(checker.logger).to have_received(:display).with('api_key_missing')
    end

    it 'should display error if no application id' do
      # Given
      checker.config['algolia'] = {
        'application_id' => nil,
        'index_name' => 'INDEX_NAME'
      }
      stub_const('ENV', 'ALGOLIA_API_KEY' => 'APIKEY_FROM_ENV')

      # Then
      expect(-> { checker.assert_valid }).to raise_error SystemExit
      expect(checker.logger)
        .to have_received(:display)
        .with('application_id_missing')
    end

    it 'should display error if no index name' do
      # Given
      checker.config['algolia'] = {
        'application_id' => 'APPLICATION_ID',
        'index_name' => nil
      }
      stub_const('ENV', 'ALGOLIA_API_KEY' => 'APIKEY_FROM_ENV')

      # Then
      expect(-> { checker.assert_valid }).to raise_error SystemExit
      expect(checker.logger)
        .to have_received(:display)
        .with('index_name_missing')
    end

    it 'should init the Algolia client' do
      # Given
      allow(checker).to receive(:application_id).and_return('FOO')
      allow(checker).to receive(:api_key).and_return('BAR')
      allow(Algolia).to receive(:init)

      # When
      checker.assert_valid

      # Then
      expect(Algolia).to have_received(:init).with(
        application_id: 'FOO',
        api_key: 'BAR'
      )
    end
  end
end
