# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
require 'spec_helper'

describe(Jekyll::Algolia::ErrorHandler) do
  let(:current) { Jekyll::Algolia::ErrorHandler }
  let(:configurator) { Jekyll::Algolia::Configurator }
  let(:logger) { Jekyll::Algolia::Logger }
  let(:utils) { Jekyll::Algolia::Utils }

  describe '.stop' do
    subject { -> { current.stop(error) } }

    let(:error) { double('Error') }
    let(:identified_error) { nil }
    before do
      allow(current).to receive(:identify).and_return(identified_error)
      allow(logger).to receive(:log)
    end

    context 'with unknown error' do
      let(:identified_error) { false }
      before do
        expect(logger).to receive(:log).with("E:#{error}")
      end

      it { is_expected.to raise_error SystemExit }
    end

    context 'with known error' do
      let(:identified_error) { { name: 'foo', details: 'bar' } }
      before do
        expect(logger).to receive(:known_message).with('foo', 'bar')
      end

      it { is_expected.to raise_error SystemExit }
    end
  end

  describe '.identify' do
    let(:error) { double('Error') }
    let(:context) { 'context' }

    subject { current.identify(error, context) }

    before do
      allow(current).to receive(:unknown_application_id?).and_return(false)
      allow(current).to receive(:invalid_credentials?).and_return(false)
      allow(current).to receive(:record_too_big?).and_return(false)
      allow(current).to receive(:too_many_records?).and_return(false)
      allow(current).to receive(:unknown_setting?).and_return(false)
      allow(current).to receive(:invalid_index_name?).and_return(false)
    end

    it 'should return false if nothing matches' do
      should eq false
    end

    describe 'should call all methods with error and context' do
      before do
        current.identify(error, context)
      end
      it do
        expect(current)
          .to have_received(:unknown_application_id?)
          .with(error, context)
        expect(current)
          .to have_received(:invalid_credentials?)
          .with(error, context)
        expect(current)
          .to have_received(:record_too_big?)
          .with(error, context)
        expect(current)
          .to have_received(:too_many_records?)
          .with(error, context)
        expect(current)
          .to have_received(:unknown_setting?)
          .with(error, context)
        expect(current)
          .to have_received(:invalid_index_name?)
          .with(error, context)
      end
    end

    describe 'should return the result of one if matches' do
      before do
        allow(current)
          .to receive(:too_many_records?)
          .and_return('foo')
      end

      it do
        should eq(name: 'too_many_records', details: 'foo')
      end
    end
  end

  describe '.error_hash' do
    subject { current.error_hash(message) }

    context 'with a regular error message' do
      let(:message) do
        'Cannot POST to '\
        'https://MY_APP_ID.algolia.net/1/section/index_name/action: '\
        '{"message":"Custom message","status":403}'\
        "\n (403)"
      end

      it do
        should include('verb' => 'POST')
        should include('scheme' => 'https')
        should include('application_id' => 'MY_APP_ID')
        should include('api_version' => 1)
        should include('api_section' => 'section')
        should include('index_name' => 'index_name')
        should include('api_action' => 'action')
        should include('message' => 'Custom message')
        should include('status' => 403)
      end
    end

    context 'with a message with query parameters' do
      let(:message) do
        'Cannot POST to '\
        'https://MY_APP_ID.algolia.net/1/section/index_name/action?foo=bar: '\
        '{"message":"Custom message","status":403}'\
        "\n (403)"
      end

      it do
        should include('foo' => 'bar')
      end
    end

    context 'with an error message with weird characaters' do
      let(:message) do
        'Cannot POST to '\
        'https://MY_APP_ID.algolia.net/1/section/index_name$`!</action: '\
        '{"message":"Custom message","status":403}'\
        "\n (403)"
      end

      it do
        should include('index_name' => 'index_name$`!<')
      end
    end

    context 'with a malformed error message' do
      let(:message) { 'Unable to even parse this' }

      it { should eq false }
    end
  end

  describe '.readable_largest_record_keys' do
    let(:record) { { foo: foo, bar: bar, baz: baz, small: 'xxx' } }
    let(:foo) { 'x' * 1000 }
    let(:bar) { 'x' * 10_000 }
    let(:baz) { 'x' * 100_000 }

    subject { current.readable_largest_record_keys(record) }

    it { should eq 'baz (100.00 Kb), bar (10.00 Kb), foo (1.00 Kb)' }
  end

  describe '.unknown_application_id?' do
    let(:error) { double('Error', message: message) }

    subject { current.unknown_application_id?(error) }

    describe 'not matching' do
      let(:message) { 'foo bar' }
      it { should eq false }
    end

    describe 'matching' do
      let(:message) do
        # rubocop:disable Metrics/LineLength
        'Cannot reach any host: '\
          'getaddrinfo: Name or service not known (MY_APP_ID-dsn.algolia.net:443), '\
          'getaddrinfo: No address associated with hostname (MY_APP_ID-3.algolianet.com:443), '\
          'getaddrinfo: No address associated with hostname (MY_APP_ID-1.algolianet.com:443), '\
          'getaddrinfo: No address associated with hostname (MY_APP_ID-2.algolianet.com:443)'
        # rubocop:enable Metrics/LineLength
      end

      it { should eq('application_id' => 'MY_APP_ID') }
    end

    describe 'matching with a DSN' do
      let(:message) do
        # rubocop:disable Metrics/LineLength
        'Cannot reach any host: '\
        'getaddrinfo: Name or service not known (MY_APP_ID.algolia.net:443), '\
        'getaddrinfo: No address associated with hostname (MY_APP_ID-3.algolianet.com:443), '\
        'getaddrinfo: No address associated with hostname (MY_APP_ID-1.algolianet.com:443), '\
        'getaddrinfo: No address associated with hostname (MY_APP_ID-2.algolianet.com:443)'
        # rubocop:enable Metrics/LineLength
      end

      it { should eq('application_id' => 'MY_APP_ID') }
    end
  end

  describe '.invalid_credentials?' do
    let(:error) { double('Error').as_null_object }

    subject { current.invalid_credentials?(error) }

    before do
      allow(current).to receive(:error_hash).and_return(error_hash)
    end

    describe 'not matching' do
      let(:error_hash) { false }
      it { should eq false }
    end

    context 'with wrong API key' do
      let(:error_hash) do
        {
          'message' => 'Invalid Application-ID or API key',
          'application_id' => 'MY_APP_ID'
        }
      end
      it { should eq('application_id' => 'MY_APP_ID') }
    end
  end

  describe '.record_too_big?' do
    let(:error) { double('Error').as_null_object }
    let(:error_hash) do
      {
        'message' => 'Record at the position 3 '\
                     'objectID=deadbeef is too big size=109196 bytes. '\
                     'Contact us if you need an extended quota',
        'objectID' => 'object_id'
      }
    end
    let(:context) do
      {
        operations: [
          {
            action: 'deleteObject',
            body: { objectID: 'object_to_delete' }
          },
          {
            action: 'addObject',
            body: { objectID: 'object_id', title: 'foo', url: 'url' }
          },
          {
            action: 'clear'
          },
          {
            action: 'addObject',
            body: { content: %w[object_id1 object_id2] }
          }
        ]
      }
    end

    subject { current.record_too_big?(error, context) }

    before do
      allow(current).to receive(:error_hash).and_return(error_hash)
      allow(utils).to receive(:find_by_key).and_return({})
      allow(current).to receive(:readable_largest_record_keys)
      allow(logger).to receive(:write_to_file)
    end

    describe 'wrongly formatted message' do
      let(:error_hash) { false }

      it { should eq false }
    end

    describe 'not matching' do
      let(:error_hash) { { 'message' => 'foo bar' } }

      it { should eq false }
    end

    it 'should get information from message' do
      should include('object_id' => 'object_id')
      should include('size' => '109.20 Kb')
      should include('size_limit' => '10 Kb')
    end

    describe 'includes the nodes to index' do
      before do
        allow(configurator).to receive(:algolia).and_return('nodes')
      end

      it do
        should include('nodes_to_index' => 'nodes')
      end
    end

    describe 'includes information about the bad record' do
      before do
        allow(current)
          .to receive(:readable_largest_record_keys)
          .and_return('wrong_keys')
      end

      it do
        should include('object_title' => 'foo')
        should include('object_url' => 'url')
        should include('probable_wrong_keys' => 'wrong_keys')
      end
    end

    describe 'save log file' do
      before do
        expect(::JSON)
          .to receive(:pretty_generate)
          .with(objectID: 'object_id', title: 'foo', url: 'url')
          .and_return('{json}')
        expect(logger)
          .to receive(:write_to_file)
          .with(
            'jekyll-algolia-record-too-big-object_id.log',
            '{json}'
          )
          .and_return('/path/to/file.log')
      end

      it 'should return the path of the log file in the output' do
        should include('record_log_path' => '/path/to/file.log')
      end
    end
  end

  describe '.unknown_setting?' do
    let(:error) { double('Error').as_null_object }
    let(:context) do
      {
        settings: {
          'iDontExist' => 'foo'
        }
      }
    end

    subject { current.unknown_setting?(error, context) }

    before do
      allow(current).to receive(:error_hash).and_return(error_hash)
    end

    describe 'not matching' do
      let(:error_hash) { false }
      it { should eq false }
    end

    context 'with non-existent setting' do
      let(:error_hash) do
        {
          'message' => 'Invalid object attributes: iDontExist '\
                       'near line:1 column:456'
        }
      end
      it do
        should include('setting_name' => 'iDontExist')
        should include('setting_value' => 'foo')
      end
    end
  end

  describe '.invalid_index_name?' do
    let(:error) { double('Error').as_null_object }

    subject { current.invalid_index_name?(error) }

    before do
      allow(current).to receive(:error_hash).and_return(error_hash)
      allow(configurator).to receive(:index_name).and_return('my_index')
    end

    describe 'not matching' do
      let(:error_hash) { false }
      it { should eq false }
    end

    context 'with invalid index name' do
      let(:error_hash) do
        {
          'message' => 'indexName is not valid'
        }
      end
      it do
        should include('index_name' => 'my_index')
      end
    end
  end

  describe '.too_many_records?' do
    let(:error) { double('Error').as_null_object }

    subject { current.too_many_records?(error) }

    before do
      allow(current).to receive(:error_hash).and_return(error_hash)
    end

    describe 'not matching' do
      let(:error_hash) { false }
      it { should eq false }
    end

    context 'with quota exceeded' do
      let(:error_hash) do
        {
          'message' => 'Record quota exceeded, change plan or delete records.'
        }
      end
      it do
        should eq({})
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
