require 'spec_helper'

describe(AlgoliaSearchJekyllPush) do
  let(:push) { AlgoliaSearchJekyllPush }
  let(:options) do
    {
      'drafts' => true
    }
  end
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
  let(:static_file) do
    Jekyll::StaticFile.new('site', 'base', 'dir', 'static.pdf')
  end
  let(:index) do

  end

  def mock_page(name)
    MockPage.new(name)
  end

  describe 'init_options' do
    it 'sets options and config' do
      # Given
      args = nil

      # When
      push.init_options(args, options, config)

      # Then
      expect(push.options).to eq(options)
      expect(push.config).to eq(config)
    end

    it 'sets indexname from the commandline' do
      # Given
      args = ['newindex']

      # When
      push.init_options(args, options, config)

      # Then
      expect(push.config['algolia']['index_name']).to eq 'newindex'
    end
  end

  describe 'excluded_file?' do
    before(:each) do
      push.init_options(nil, options, config)
    end

    it 'exclude StaticFiles' do
      expect(push.indexable?(static_file)).to eq false
    end

    it 'keeps markdown files' do
      expect(push.indexable?(mock_page('page.md'))).to eq true
    end

    it 'keeps html files' do
      expect(push.indexable?(mock_page('page.html'))).to eq true
    end

    it 'exclude file specified in config' do
      # Given
      config['algolia']['excluded_files'] = [
        'excluded.html'
      ]
      push.init_options(nil, options, config)

      # Then
      expect(push.indexable?(mock_page('excluded.html'))).to eq false
    end
  end

  describe 'api_key' do
    it 'returns nil if no key found' do
      # Given
      push.init_options(nil, options, config)

      # When
      expect(push.api_key).to be_nil
    end

    it 'reads from ENV var if set' do
      # Given
      push.init_options(nil, options, config)
      stub_const('ENV', 'ALGOLIA_API_KEY' => 'APIKEY_FROM_ENV')

      # When
      actual = push.api_key

      # Then
      expect(actual).to eq 'APIKEY_FROM_ENV'
    end

    it 'reads from _algolia_api_key in source if set' do
      # Given
      config['source'] = File.join(config['source'], 'api_key_dir')
      push.init_options(nil, options, config)

      # When
      actual = push.api_key

      # Then
      expect(actual).to eq 'APIKEY_FROM_FILE'
    end

    it 'reads from ENV before from file' do
      # Given
      config['source'] = File.join(config['source'], 'api_key_dir')
      stub_const('ENV', 'ALGOLIA_API_KEY' => 'APIKEY_FROM_ENV')
      push.init_options(nil, options, config)

      # When
      actual = push.api_key

      # Then
      expect(actual).to eq 'APIKEY_FROM_ENV'
    end
  end

  describe 'check_credentials' do
    it 'should display error if no api key' do
      # Given
      config['algolia'] = {
        'application_id' => 'APP_ID',
        'index_name' => 'INDEX_NAME'
      }
      push.init_options(nil, options, config)

      # Then
      expect(Jekyll.logger).to receive(:error).with(/api key/i)
      expect(Jekyll.logger).to receive(:warn).at_least(:once)
      expect(-> { push.check_credentials }).to raise_error SystemExit
    end

    it 'should display error if no application id' do
      # Given
      config['algolia'] = {
        'application_id' => nil,
        'index_name' => 'INDEX_NAME'
      }
      stub_const('ENV', 'ALGOLIA_API_KEY' => 'APIKEY_FROM_ENV')
      push.init_options(nil, options, config)

      # Then
      expect(Jekyll.logger).to receive(:error).with(/application id/i)
      expect(Jekyll.logger).to receive(:warn).at_least(:once)
      expect(-> { push.check_credentials }).to raise_error SystemExit
    end

    it 'should display error if no index name' do
      # Given
      config['algolia'] = {
        'application_id' => 'APPLICATION_ID',
        'index_name' => nil
      }
      stub_const('ENV', 'ALGOLIA_API_KEY' => 'APIKEY_FROM_ENV')
      push.init_options(nil, options, config)

      # Then
      expect(Jekyll.logger).to receive(:error).with(/index name/i)
      expect(Jekyll.logger).to receive(:warn).at_least(:once)
      expect(-> { push.check_credentials }).to raise_error SystemExit
    end
  end

  fdescribe 'configure_index' do
    it 'sets some sane defaults' do
      # Given
      push.init_options(nil, options, config)
      index = double

      # Then
      expected = {
        attributeForDistinct: 'title',
        distinct: true,
        customRanking: ['desc(posted_at)', 'desc(title_weight)'],
        typoTolerance: true
      }
      expect(index).to receive(:set_settings).with(hash_including(expected))

      # When
      push.configure_index(index)
    end

    it 'allow user to override all settings' do
      # Given
      settings = {
        distinct: false,
        customSetting: 'foo',
        customRanking: ['asc(foo)', 'desc(bar)']
      }
      config['algolia']['settings'] = settings
      push.init_options(nil, options, config)
      index = double

      # Then
      expect(index).to receive(:set_settings).with(hash_including(settings))

      # When
      push.configure_index(index)
    end
  end
end
