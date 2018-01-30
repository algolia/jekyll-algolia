# rubocop:disable Metrics/BlockLength
# frozen_string_literal: true

require 'spec_helper'

describe(Jekyll::Algolia::Indexer) do
  let(:current) { Jekyll::Algolia::Indexer }
  let(:configurator) { Jekyll::Algolia::Configurator }
  let(:logger) { Jekyll::Algolia::Logger }
  let(:dry_run) { false }
  before { allow(configurator).to receive(:dry_run?).and_return(dry_run) }
  before { allow(logger).to receive(:log) }

  describe '.init' do
    before do
      allow(configurator).to receive(:application_id).and_return('app_id')
      allow(configurator).to receive(:api_key).and_return('api_key')
      allow(::Algolia).to receive(:init)
      allow(current).to receive(:set_user_agent)
    end

    before { current.init }

    it 'should instanciate Algolia search with application id and api_key' do
      expect(::Algolia)
        .to have_received(:init)
        .with(hash_including(
                application_id: 'app_id',
                api_key: 'api_key'
        ))
    end
    it 'should set the user agent' do
      expect(current).to have_received(:set_user_agent)
    end
  end

  describe '.set_user_agent' do
    let(:user_agent) do
      'Jekyll Integration (vIntegration); '\
      'Algolia for Ruby (vAlgolia); '\
      'Jekyll (vJekyll); '\
      'Ruby (vRuby)'
    end

    before do
      stub_const('Jekyll::Algolia::VERSION', 'vIntegration')
      stub_const('::Algolia::VERSION', 'vAlgolia')
      stub_const('::Jekyll::VERSION', 'vJekyll')
      stub_const('RUBY_VERSION', 'vRuby')

      allow(::Algolia).to receive(:set_extra_header)
    end

    before { current.set_user_agent }

    it do
      expect(::Algolia)
        .to have_received(:set_extra_header)
        .with('User-Agent', user_agent)
    end
  end

  describe '.index' do
    subject { current.index(input) }

    let(:input) { 'index_name' }
    before do
      expect(::Algolia::Index)
        .to receive(:new)
        .with('index_name')
        .and_return('custom_index')
    end

    it { should eq 'custom_index' }
  end

  describe '.remote_object_ids' do
    subject { current.remote_object_ids(index) }

    let(:index) { double('Algolia::Index').as_null_object }

    before do
      expect(index)
        .to receive(:browse)
        .with(attributesToRetrieve: 'objectID')
        .and_yield('objectID' => 'foo')
        .and_yield('objectID' => 'bar')
    end

    it { should include('foo') }
    it { should include('bar') }
    # Should be ordered
    it { should eq %w[bar foo] }
  end

  describe '.local_object_ids' do
    subject { current.local_object_ids(records) }

    let(:records) { [{ objectID: 'foo' }, { objectID: 'bar' }] }

    it { should include('foo') }
    it { should include('bar') }
    # Should be ordered
    it { should eq %w[bar foo] }

    context 'with records missing their objectID' do
      let(:records) do
        [
          { objectID: 'foo' },
          { foo: 'foo' },
          { objectID: 'bar' },
          { bar: 'bar' }
        ]
      end
      it { should eq %w[bar foo] }
    end
  end

  describe '.update_settings' do
    let(:index) { double('Algolia::Index', set_settings!: nil) }
    let(:settings) { { 'foo' => 'bar' } }
    before { current.update_settings(index, settings) }

    it do
      expect(index).to have_received(:set_settings!).with(settings)
    end

    context 'when running a dry run' do
      let(:dry_run) { true }

      it do
        expect(index)
          .to_not have_received(:set_settings!)
      end
    end
  end

  describe '.update_records' do
    let(:index_name) { 'my_index' }
    let(:old_records_ids) { %w[abc] }
    let(:new_records) { [{ 'objectID' => 'def' }] }
    let(:indexing_batch_size) { 1000 }

    before { allow(::Algolia).to receive(:batch!) }
    before do
      allow(configurator)
        .to receive(:algolia)
        .with('indexing_batch_size')
        .and_return(indexing_batch_size)
    end
    before { current.update_records(index_name, old_records_ids, new_records) }

    context 'when running a dry run' do
      let(:dry_run) { true }
      it do
        expect(::Algolia)
          .to_not have_received(:batch!)
      end
    end

    context 'when nothing to update' do
      let(:old_records_ids) { [] }
      let(:new_records) { [] }
      it do
        expect(::Algolia)
          .to_not have_received(:batch!)
      end
    end

    it 'should batch all operations' do
      expect(::Algolia)
        .to have_received(:batch!)
        .with([
                {
                  action: 'addObject',
                  indexName: 'my_index',
                  body: { 'objectID' => 'def' }
                },
                {
                  action: 'deleteObject',
                  indexName: 'my_index',
                  body: { objectID: 'abc' }
                }
              ])
    end

    context 'split in smaller batches if too many operations' do
      let(:indexing_batch_size) { 1 }
      it do
        expect(::Algolia)
          .to have_received(:batch!)
          .ordered
          .with([
                  {
                    action: 'addObject',
                    indexName: 'my_index',
                    body: { 'objectID' => 'def' }
                  }
                ])
        expect(::Algolia)
          .to have_received(:batch!)
          .ordered
          .with([
                  {
                    action: 'deleteObject',
                    indexName: 'my_index',
                    body: { objectID: 'abc' }
                  }
                ])
      end
    end
  end

  describe '.run' do
    let(:records) { [{ objectID: 'foo' }, { objectID: 'bar' }] }
    let(:remote_ids) { %w[foo baz] }
    let(:settings) { 'settings' }
    let(:index_name) { 'my_index' }
    before do
      allow(configurator).to receive(:settings).and_return(settings)
      allow(configurator).to receive(:index_name).and_return(index_name)
      allow(current).to receive(:init)
      allow(current).to receive(:index).and_return('my_index')
      allow(current).to receive(:update_settings)
      allow(current).to receive(:remote_object_ids).and_return(remote_ids)
      allow(current).to receive(:update_records)
    end

    context 'with records' do
      before { current.run(records) }

      it { expect(current).to have_received(:init) }
      it do
        expect(current)
          .to have_received(:update_settings)
          .with('my_index', settings)
      end
      it do
        expect(current)
          .to have_received(:update_records)
          .with(index_name, ['baz'], [{ objectID: 'bar' }])
      end
    end

    context 'with empty results' do
      subject { -> { current.run(records) } }

      let(:records) { [] }

      before do
        expect(configurator)
          .to receive(:algolia)
          .with('files_to_exclude')
          .and_return(%w[foo.html bar.md])
        expect(configurator)
          .to receive(:algolia)
          .with('nodes_to_index')
          .and_return('p,li')
        expect(logger)
          .to receive(:known_message)
          .with(
            'no_records_found',
            hash_including(
              'files_to_exclude' => 'foo.html, bar.md',
              'nodes_to_index' => 'p,li'
            )
          )
      end

      it { is_expected.to raise_error SystemExit }
    end
  end
end
# rubocop:enable Metrics/BlockLength
