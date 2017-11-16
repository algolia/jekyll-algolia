# rubocop:disable Metrics/BlockLength
require 'spec_helper'

describe(Jekyll::Algolia::ErrorHandler) do
  let(:current) { Jekyll::Algolia::ErrorHandler }
  let(:configurator) { Jekyll::Algolia::Configurator }

  describe '.identify' do
    subject { current.identify(error, context) }

    let(:error) { double('Error', message: message) }
    let(:context) { {} }

    context 'with unknown application_id' do
      let(:message) do
        'Cannot reach any host: '\
        'getaddrinfo: Name or service not known (MY_APP_ID.algolia.net:443), '\
        'getaddrinfo: No address associated with hostname (MY_APP_ID-3.algolianet.com:443), '\
        'getaddrinfo: No address associated with hostname (MY_APP_ID-1.algolianet.com:443), '\
        'getaddrinfo: No address associated with hostname (MY_APP_ID-2.algolianet.com:443)'
      end

      it { should include(name: 'unknown_application_id') }
      it { should include(details: { 'application_id' => 'MY_APP_ID' }) }
    end

    context 'with no access to the _tmp index' do
      before do
        allow(configurator)
          .to receive(:index_name)
          .and_return('my_index')
      end
      let(:message) do
        'Cannot POST to '\
        'https://MY_APP_ID.algolia.net/1/indexes/my_index_tmp/batch: '\
        '{"message":"Invalid Application-ID or API key","status":403}'\
        "\n (403)"
      end

      it { should include(name: 'invalid_credentials_for_tmp_index') }
      it do
        should include(details: {
                         'application_id' => 'MY_APP_ID',
                         'index_name' => 'my_index',
                         'index_name_tmp' => 'my_index_tmp'
                       })
      end
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
                         'application_id' => 'MY_APP_ID',
                         'index_name' => 'my_index'
                       })
      end
    end

    context 'with a record too big' do
      let(:message) do
        '400: Cannot POST to '\
        'https://MXM0JWJNIW.algolia.net/1/indexes/my_index/batch: '\
        '{"message":"Record at the position 3 '\
        'objectID=deadbeef is too big size=1091966 bytes. '\
        'Contact us if you need an extended quota","position":3,'\
        '"objectID":"deadbeef","status":400} (400)'
      end
      let(:context) do
        { records: [
          {
            objectID: 'deadbeef',
            title: 'Page title',
            url: '/path/to/file.ext',
            text: 'A very long text that is obviously too long to fit in one record, but that would be too long to actually display in the error message as wel so we will cut it at 100 characters.'
          },
          { objectID: 'foo' }
        ] }
      end

      it { should include(name: 'record_too_big') }
      it do
        details = subject[:details]
        expect(details).to include('object_id' => 'deadbeef')
        expect(details).to include('object_title' => 'Page title')
        expect(details).to include('object_url' => '/path/to/file.ext')
        expect(details['object_hint']).to match(/^A very long text/)
        expect(details['object_hint']).to match(/.{0,100}/)
        expect(details).to include('size' => '1.04 MiB')
        expect(details).to include('size_limit' => '10 Kb')
      end
    end
  end
end
