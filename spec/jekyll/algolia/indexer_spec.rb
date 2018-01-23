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

  describe 'index?' do
    subject { current.index?('foo') }

    let(:index) { double('Algolia::Index', get_settings: nil) }
    before do
      expect(current)
        .to receive(:index)
        .and_return(index)
    end

    it { should eq true }

    context 'when no settings' do
      before do
        expect(index).to receive(:get_settings).and_raise
      end

      it { should eq false }
    end
  end

  describe 'update_records' do
    let(:index) do
      double('Algolia::Index', add_objects!: nil, name: 'my_index')
    end

    context 'with a small number of records' do
      let(:records) { Array.new(10, foo: 'bar') }
      before { current.update_records(index, records) }
      it do
        expect(index)
          .to have_received(:add_objects!)
          .with(records)
          .once
      end
    end
    context 'with a large number of records' do
      let(:records) { Array.new(2500, foo: 'bar') }
      before { current.update_records(index, records) }
      it do
        expect(index)
          .to have_received(:add_objects!)
          .exactly(3).times
      end
    end
    context 'with a custom batch size' do
      let(:records) { Array.new(2500, foo: 'bar') }
      before do
        allow(configurator)
          .to receive(:algolia)
          .with('indexing_batch_size')
          .and_return(500)
      end
      before { current.update_records(index, records) }
      it do
        expect(index)
          .to have_received(:add_objects!)
          .exactly(5).times
      end
    end

    context 'when running a dry run' do
      let(:dry_run) { true }
      let(:records) { Array.new(10, foo: 'bar') }

      it do
        expect(index)
          .to_not have_received(:add_objects!)
          .with(records)
      end
    end
  end

  describe '.delete_records_by_id' do
    let(:index) do
      double('Algolia::Index', delete_objects!: nil, name: 'my_index')
    end
    let(:ids) { %w[foo bar baz] }

    before { current.delete_records_by_id(index, ids) }

    it do
      expect(index)
        .to have_received(:delete_objects!)
        .with(ids)
    end

    context 'when running a dry run' do
      let(:dry_run) { true }

      it do
        expect(index)
          .to_not have_received(:delete_objects!)
          .with(ids)
      end
    end

    context 'when deleting zero records' do
      let(:ids) { [] }
      before do
        allow(logger).to receive(:log)
      end
      it do
        expect(logger).to_not have_received(:log)
        expect(index).to_not have_received(:delete_objects!)
      end
    end
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

  describe '.run_diff_mode' do
    let(:local_records) do
      [
        { objectID: 'foo' },
        { objectID: 'bar' }
      ]
    end
    let(:remote_ids) { %w[foo baz] }
    before do
      allow(current)
        .to receive(:index)
        .and_return(
          double('Algolia::Index', new: 'my_index', name: 'my_index')
        )
      allow(current).to receive(:remote_object_ids).and_return(remote_ids)
      allow(current).to receive(:delete_records_by_id)
      allow(current).to receive(:update_records)
      allow(current).to receive(:update_settings)
      allow(configurator).to receive(:settings).and_return('my_settings')
    end

    before { current.run_diff_mode(local_records) }

    it do
      expect(current)
        .to have_received(:delete_records_by_id)
        .with(anything, ['baz'])
      expect(current)
        .to have_received(:update_records)
        .with(anything, [{ objectID: 'bar' }])
      expect(current)
        .to have_received(:update_settings)
        .with(anything, 'my_settings')
    end

    context 'nothing changed since last update' do
      let(:local_records) do
        [
          { objectID: 'foo' },
          { objectID: 'bar' }
        ]
      end
      let(:remote_ids) { %w[foo bar] }

      before do
        allow(logger).to receive(:log)
      end
      it do
        expect(logger).to have_received(:log).with(/Nothing to index/)
      end
    end
  end

  describe '.rename_index' do
    before { allow(::Algolia).to receive(:move_index!) }
    before { current.rename_index('foo', 'bar') }

    it do
      expect(::Algolia).to have_received(:move_index!).with('foo', 'bar')
    end

    context 'when running a dry run' do
      let(:dry_run) { true }

      it do
        expect(::Algolia)
          .to_not have_received(:move_index!)
      end
    end
  end

  describe '.copy_index' do
    let(:index_exists) { true }

    before do
      allow(current).to receive(:index?).and_return(index_exists)
      allow(::Algolia).to receive(:copy_index!)

      current.copy_index('foo', 'bar')
    end

    it do
      expect(::Algolia).to have_received(:copy_index!).with('foo', 'bar')
    end

    context 'when no source index' do
      let(:index_exists) { false }
      it do
        expect(::Algolia)
          .to_not have_received(:copy_index!)
      end
    end

    context 'when running a dry run' do
      let(:dry_run) { true }

      it do
        expect(::Algolia)
          .to_not have_received(:copy_index!)
      end
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

  describe '.remote_settings' do
    subject { current.remote_settings(index) }

    let(:index) { double('Algolia::Index').as_null_object }
    before do
      expect(index)
        .to receive(:get_settings)
        .and_return('custom_settings')
    end

    it { should eq 'custom_settings' }
  end

  describe '.run_atomic_mode' do
    let(:local_records) do
      [
        { objectID: 'foo' },
        { objectID: 'bar' }
      ]
    end
    let(:remote_ids) { %w[foo baz] }
    let(:index) { double('Algolia::Index', new: 'my_index', name: 'my_index') }
    let(:index_tmp) do
      double('Algolia::Index', new: 'my_index_tmp', name: 'my_index_tmp')
    end
    before do
      allow(configurator).to receive(:index_name).and_return('my_index')
      allow(configurator).to receive(:settings).and_return('settings')
      allow(current).to receive(:index).with('my_index').and_return(index)
      allow(current)
        .to receive(:index).with('my_index_tmp').and_return(index_tmp)
      allow(current).to receive(:remote_object_ids).and_return(remote_ids)
      allow(current).to receive(:copy_index)
      allow(current).to receive(:update_settings)
      allow(current).to receive(:delete_records_by_id)
      allow(current).to receive(:update_records)
      allow(current).to receive(:rename_index)
    end

    before { current.run_atomic_mode(local_records) }

    it do
      expect(current)
        .to have_received(:copy_index)
        .with('my_index', 'my_index_tmp')
      expect(current)
        .to have_received(:update_settings)
        .with(index_tmp, 'settings')
      expect(current)
        .to have_received(:delete_records_by_id)
        .with(index_tmp, ['baz'])
      expect(current)
        .to have_received(:update_records)
        .with(index_tmp, [{ objectID: 'bar' }])
      expect(current)
        .to have_received(:rename_index)
        .with('my_index_tmp', 'my_index')
    end

    context 'nothing changed since last update' do
      let(:local_records) do
        [
          { objectID: 'foo' },
          { objectID: 'bar' }
        ]
      end
      let(:remote_ids) { %w[foo bar] }

      before do
        allow(logger).to receive(:log)
      end
      it do
        expect(logger).to have_received(:log).with(/Nothing to index/)
      end
    end
  end

  describe '.run' do
    let(:indexing_mode) { 'diff' }
    before do
      allow(current).to receive(:init)
      allow(current).to receive(:run_diff_mode)
      allow(current).to receive(:run_atomic_mode)
      allow(configurator).to receive(:indexing_mode).and_return(indexing_mode)
    end

    context 'with records' do
      let(:records) { [{ 'objectID' => 'foo' }, { 'objectID' => 'bar' }] }

      before { current.run(records) }

      it { expect(current).to have_received(:init) }

      context 'when in diff mode' do
        let(:indexing_mode) { 'diff' }
        it { expect(current).to have_received(:run_diff_mode) }
        it { expect(current).to_not have_received(:run_atomic_mode) }
      end
      context 'when in atomic mode' do
        let(:indexing_mode) { 'atomic' }
        it { expect(current).to have_received(:run_atomic_mode) }
        it { expect(current).to_not have_received(:run_diff_mode) }
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
