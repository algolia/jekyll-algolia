# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
require 'spec_helper'

describe(Jekyll::Algolia::ErrorHandler) do
  let(:current) { Jekyll::Algolia::ErrorHandler }
  let(:configurator) { Jekyll::Algolia::Configurator }
  let(:logger) { Jekyll::Algolia::Logger }

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

  describe '.identify' do
    subject { current.identify(error, context) }

    let(:error) { double('Error', message: message) }
    let(:context) { {} }

    context 'with unknown application_id' do
      let(:message) do
        # rubocop:disable Metrics/LineLength
        'Cannot reach any host: '\
        'getaddrinfo: Name or service not known (MY_APP_ID-dsn.algolia.net:443), '\
        'getaddrinfo: No address associated with hostname (MY_APP_ID-3.algolianet.com:443), '\
        'getaddrinfo: No address associated with hostname (MY_APP_ID-1.algolianet.com:443), '\
        'getaddrinfo: No address associated with hostname (MY_APP_ID-2.algolianet.com:443)'
        # rubocop:enable Metrics/LineLength
      end

      it { should include(name: 'unknown_application_id') }
      it { should include(details: { 'application_id' => 'MY_APP_ID' }) }
    end

    context 'with unknown application_id and no DSN' do
      let(:message) do
        # rubocop:disable Metrics/LineLength
        'Cannot reach any host: '\
        'getaddrinfo: Name or service not known (MY_APP_ID.algolia.net:443), '\
        'getaddrinfo: No address associated with hostname (MY_APP_ID-3.algolianet.com:443), '\
        'getaddrinfo: No address associated with hostname (MY_APP_ID-1.algolianet.com:443), '\
        'getaddrinfo: No address associated with hostname (MY_APP_ID-2.algolianet.com:443)'
        # rubocop:enable Metrics/LineLength
      end

      it { should include(name: 'unknown_application_id') }
      it { should include(details: { 'application_id' => 'MY_APP_ID' }) }
    end

    context 'with wrong API key' do
      before do
        allow(configurator)
          .to receive(:index_name)
          .and_return('my_index')
      end
      let(:message) do
        'Cannot POST to '\
        'https://MY_APP_ID.algolia.net/1/indexes/my_index/batch: '\
        '{"message":"Invalid Application-ID or API key","status":403}'\
        "\n (403)"
      end

      it { should include(name: 'invalid_credentials') }
      it do
        should include(details: {
                         'application_id' => 'MY_APP_ID'
                       })
      end
    end

    context 'with a record too big' do
      let(:message) do
        '400: Cannot POST to '\
        'https://MY_APP_ID.algolia.net/1/indexes/*/batch: '\
        '{"message":"Record at the position 3 '\
        'objectID=deadbeef is too big size=109196 bytes. '\
        'Contact us if you need an extended quota","position":3,'\
        '"objectID":"deadbeef","status":400} (400)'
      end
      let(:context) do
        { records: [
          {
            objectID: 'deadbeef',
            title: 'Page title',
            url: '/path/to/file.ext',
            # rubocop:disable Metrics/LineLength
            content: 'A very long text that is obviously too long to fit in one record, but that would be too long to actually display in the error message as well so we will cut it at 100 characters.'
            # rubocop:enable Metrics/LineLength
          },
          { objectID: 'foo' }
        ] }
      end
      let(:record_log_path) { '/source/output.log' }
      let(:probable_wrong_keys) { 'foo, bar, baz' }
      before do
        allow(configurator)
          .to receive(:algolia)
          .with('nodes_to_index')
          .and_return('p,li,foo')
        expect(logger)
          .to receive(:write_to_file)
          .and_return(record_log_path)
        expect(current)
          .to receive(:readable_largest_record_keys)
          .and_return(probable_wrong_keys)
      end

      it { should include(name: 'record_too_big') }

      it do
        details = subject[:details]
        expect(details).to include('object_id' => 'deadbeef')
        expect(details).to include('object_title' => 'Page title')
        expect(details).to include('object_url' => '/path/to/file.ext')
        expect(details).to include('record_log_path' => record_log_path)
        expect(details).to include('probable_wrong_keys' => probable_wrong_keys)
        expect(details).to include('size' => '109.20 Kb')
        expect(details).to include('size_limit' => '10 Kb')
        expect(details).to include('nodes_to_index' => 'p,li,foo')
      end
    end

    context 'with an unknown setting' do
      let(:message) do
        # rubocop:disable Metrics/LineLength
        '400: Cannot PUT to '\
        'https://MY_APP_ID.algolia.net/1/indexes/my_index/settings: '\
        '{"message":"Invalid object attributes: deadbeef near line:1 column:456",'\
        '"status":400} (400)'
        # rubocop:enable Metrics/LineLength
      end
      let(:context) do
        { settings:
          {
            'searchableAttributes' => %w[foo bar],
            'deadbeef' => 'foofoo'
          } }
      end

      it { should include(name: 'unknown_settings') }
      it do
        details = subject[:details]
        expect(details).to include('setting_name' => 'deadbeef')
        expect(details).to include('setting_value' => 'foofoo')
      end
    end

    context 'with an invalid index name' do
      before do
        allow(configurator)
          .to receive(:index_name)
          .and_return('invalid_index_name')
      end
      let(:message) do
        # rubocop:disable Metrics/LineLength
        '400: Cannot GET to '\
        'https://MY_APP_ID-dsn.algolia.net/1/indexes/invalid_index_name/settings?getVersion=2: '\
        '{"message":"indexName is not valid","status":400} (400)'
        # rubocop:enable Metrics/LineLength
      end

      it { should include(name: 'invalid_index_name') }
      it do
        details = subject[:details]
        expect(details).to include('index_name' => 'invalid_index_name')
      end
    end

    context 'with too many record' do
      let(:message) do
        '403: Cannot POST to '\
        'https://MY_APP_ID.algolia.net/1/indexes/*/batch: '\
        '{"message":"Record quota exceeded, change plan or delete records.",'\
        '"status":403} (403)'
      end

      it { should include(name: 'too_many_records') }
    end
  end
end
# rubocop:enable Metrics/BlockLength
