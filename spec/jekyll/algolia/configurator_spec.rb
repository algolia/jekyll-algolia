# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
require 'spec_helper'

describe(Jekyll::Algolia::Configurator) do
  let(:current) { Jekyll::Algolia::Configurator }
  let(:logger) { Jekyll::Algolia::Logger }
  let(:config) { {} }
  before do
    allow(Jekyll::Algolia).to receive(:config).and_return(config)
  end

  describe '.get' do
    let(:config) { { 'foo' => 'bar' } }

    subject { current.get('foo') }

    it { should eq 'bar' }
  end

  describe '.algolia' do
    subject { current.algolia(input) }

    context 'with an algolia config defined' do
      let(:config) { { 'algolia' => { 'foo' => 'bar' } } }

      context 'with a config option that is set' do
        let(:input) { 'foo' }
        it { should eq 'bar' }
      end
      context 'with a config option that is not set' do
        let(:input) { 'baz' }
        it { should eq nil }
      end
      describe 'should get the default nodes_to_index' do
        let(:input) { 'nodes_to_index' }
        it { should eq 'p' }
      end
      describe 'should get the default extensions_to_index' do
        before(:each) do
          allow(current)
            .to receive(:default_extensions_to_index)
            .and_return('foo')
        end

        let(:input) { 'extensions_to_index' }
        it { should eq 'foo' }
      end
    end

    context 'with no algolia config defined' do
      let(:input) { 'foo' }
      it { should eq nil }

      describe 'should get the default nodes_to_index' do
        let(:input) { 'nodes_to_index' }
        it { should eq 'p' }
      end
    end
  end

  describe '.default_extensions_to_index' do
    subject { current.default_extensions_to_index }

    before do
      allow(current)
        .to receive(:get)
        .with('markdown_ext')
        .and_return('foo,bar')
    end

    it { should include('html') }
    it { should include('foo') }
    it { should include('bar') }
  end

  describe '.default_files_to_exclude' do
    subject { current.default_files_to_exclude }

    before do
      allow(current)
        .to receive(:algolia)
        .with('extensions_to_index')
        .and_return(%w[foo bar])
    end

    it { should include('index.foo') }
    it { should include('index.bar') }
  end

  describe '.index_name' do
    subject { current.index_name }

    describe 'should return nil if none configured' do
      it { should eq nil }
    end
    describe 'should return the value in _config.yml if set' do
      let(:config) { { 'algolia' => { 'index_name' => 'foo' } } }
      it { should eq 'foo' }
    end
    describe 'should return the value in ENV is set' do
      before { stub_const('ENV', 'ALGOLIA_INDEX_NAME' => 'bar') }
      it { should eq 'bar' }
    end
    describe 'should prefer the value in ENV rather than config if set' do
      let(:config) { { 'algolia' => { 'index_name' => 'foo' } } }
      before { stub_const('ENV', 'ALGOLIA_INDEX_NAME' => 'bar') }
      it { should eq 'bar' }
    end
  end

  describe '.application_id' do
    subject { current.application_id }

    describe 'should return nil if none configured' do
      it { should eq nil }
    end
    describe 'should return the value in _config.yml if set' do
      let(:config) { { 'algolia' => { 'application_id' => 'foo' } } }
      it { should eq 'foo' }
    end
    describe 'should return the value in ENV is set' do
      let(:config) { {} }
      before { stub_const('ENV', 'ALGOLIA_APPLICATION_ID' => 'bar') }
      it { should eq 'bar' }
    end
    describe 'should prefer the value in ENV rather than config if set' do
      let(:config) { { 'algolia' => { 'application_id' => 'foo' } } }
      before { stub_const('ENV', 'ALGOLIA_APPLICATION_ID' => 'bar') }
      it { should eq 'bar' }
    end
  end

  describe '.api_key' do
    subject { current.api_key }

    describe 'should return nil if none configured' do
      it { should eq nil }
    end
    describe 'should return the value in ENV is set' do
      before { stub_const('ENV', 'ALGOLIA_API_KEY' => 'bar') }
      it { should eq 'bar' }
    end
    describe 'should return the value in _algolia_api_key file' do
      let(:config) { { 'source' => './spec/site' } }
      it { should eq 'APIKEY_FROM_FILE' }
    end
    describe 'should prefer the value in ENV rather than in the file' do
    end
  end

  describe '.assert_valid_credentials' do
    subject { current.assert_valid_credentials }

    let(:application_id) { nil }
    let(:index_name) { nil }
    let(:api_key) { nil }
    before do
      allow(current).to receive(:application_id).and_return(application_id)
      allow(current).to receive(:index_name).and_return(index_name)
      allow(current).to receive(:api_key).and_return(api_key)
    end

    context 'with no application id' do
      before do
        expect(Jekyll::Algolia::Logger)
          .to receive(:known_message)
          .with('missing_application_id')
      end
      it { should eq false }
    end

    context 'with no index name' do
      let(:application_id) { 'application_id' }
      before do
        expect(Jekyll::Algolia::Logger)
          .to receive(:known_message)
          .with('missing_index_name')
      end
      it { should eq false }
    end

    context 'with no API key' do
      let(:application_id) { 'application_id' }
      let(:index_name) { 'index_name' }
      before do
        expect(Jekyll::Algolia::Logger)
          .to receive(:known_message)
          .with('missing_api_key')
      end
      it { should eq false }
    end

    context 'with app id, index name and api key' do
      let(:application_id) { 'application_id' }
      let(:index_name) { 'index_name' }
      let(:api_key) { 'api_key' }

      it { should eq true }
    end
  end

  describe '.settings' do
    subject { current.settings }

    context 'with no custom settings' do
      it { should include('distinct' => true) }
      it { should include('attributeForDistinct' => 'url') }
      it {
        should include('customRanking' => [
                         'desc(date)',
                         'desc(weight.heading)',
                         'asc(weight.position)'
                       ])
      }
    end
    context 'with custom settings' do
      before do
        allow(current)
          .to receive(:algolia)
          .with('settings')
          .and_return('foo' => 'bar',
                      'attributeForDistinct' => 'title',
                      'customRanking' => ['asc(foo)', 'desc(bar)'])
      end

      it { should include('foo' => 'bar') }
      it { should include('distinct' => true) }
      it { should include('attributeForDistinct' => 'title') }
      it { should include('customRanking' => ['asc(foo)', 'desc(bar)']) }
    end
  end

  describe 'dry_run?' do
    subject { current.dry_run? }

    before { allow(current).to receive(:get).with('dry_run').and_return(value) }

    context 'when no value passed' do
      let(:value) { nil }
      it { should eq false }
    end
    context 'when passed true' do
      let(:value) { true }
      it { should eq true }
    end
    context 'when passed false' do
      let(:value) { false }
      it { should eq false }
    end
    context 'when passed invalid value' do
      let(:value) { 'chunky bacon' }
      it { should eq false }
    end
  end

  describe 'verbose?' do
    subject { current.verbose? }

    before { allow(current).to receive(:get).with('verbose').and_return(value) }

    context 'when no value passed' do
      let(:value) { nil }
      it { should eq false }
    end
    context 'when passed true' do
      let(:value) { true }
      it { should eq true }
    end
    context 'when passed false' do
      let(:value) { false }
      it { should eq false }
    end
    context 'when passed invalid value' do
      let(:value) { 'chunky bacon' }
      it { should eq false }
    end
  end

  describe 'warn_of_deprecated_options' do
    context 'using indexing_mode' do
      before do
        allow(current)
          .to receive(:algolia)
          .with('indexing_mode')
          .and_return(indexing_mode)
      end

      context 'with no value' do
        let(:indexing_mode) { nil }
        before do
          expect(logger).to_not receive(:log)
        end
        it { current.warn_of_deprecated_options }
      end

      context 'with a deprecated value' do
        let(:indexing_mode) { 'atomic' }
        before do
          allow(logger).to receive(:log)
          expect(logger).to receive(:log).with(/^W/).at_least(:once)
        end
        it { current.warn_of_deprecated_options }
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
