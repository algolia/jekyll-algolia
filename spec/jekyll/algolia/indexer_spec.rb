# rubocop:disable Metrics/BlockLength
require 'spec_helper'

describe(Jekyll::Algolia::Indexer) do
  let(:current) { Jekyll::Algolia::Indexer }
  let(:configurator) { Jekyll::Algolia::Configurator }
  let(:dry_run) { false }
  before { allow(configurator).to receive(:dry_run?).and_return(dry_run) }

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

  describe 'update_records' do
    let(:index) { double('Algolia::Index', add_objects!: nil) }

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
    let(:index) { double('Algolia::Index', delete_objects!: nil) }
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
        .and_return(double('Algolia::Index', new: 'my_index'))
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
  end

  describe '.rename_index' do
    before { allow(::Algolia).to receive(:move_index) }
    before { current.rename_index('foo', 'bar') }

    it do
      expect(::Algolia).to have_received(:move_index).with('foo', 'bar')
    end

    context 'when running a dry run' do
      let(:dry_run) { true }

      it do
        expect(::Algolia)
          .to_not have_received(:move_index)
      end
    end
  end

  describe '.update_settings' do
    let(:index) { double('Algolia::Index', set_settings: nil) }
    let(:settings) { { 'foo' => 'bar' } }
    before { current.update_settings(index, settings) }

    it do
      expect(index).to have_received(:set_settings).with(settings)
    end

    context 'when running a dry run' do
      let(:dry_run) { true }

      it do
        expect(index)
          .to_not have_received(:set_settings)
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
    let(:records) do
      [
        { 'objectID' => 'foo' },
        { 'objectID' => 'bar' }
      ]
    end
    let(:remote_settings) { { 'foo' => 'bar', 'bar' => 'baz' } }
    let(:local_settings) { { 'foo' => 'new_bar', 'baz' => 'deadbeef' } }
    let(:index_name) { 'my_index' }
    let(:index) { '::my_index' }
    let(:index_tmp_name) { 'my_index_tmp' }
    let(:index_tmp) { '::my_index_tmp' }

    before do
      allow(configurator).to receive(:index_name).and_return(index_name)
      allow(configurator).to receive(:settings).and_return(local_settings)
      allow(current).to receive(:index)
        .with(index_name).and_return(index)
      allow(current).to receive(:index)
        .with(index_tmp_name).and_return(index_tmp)
      allow(current).to receive(:remote_settings).and_return(remote_settings)
      allow(current).to receive(:update_records)
      allow(current).to receive(:update_settings)
      allow(current).to receive(:move_index)
    end

    before { current.run_atomic_mode(records) }

    it do
      expect(current)
        .to have_received(:update_records)
        .with(index_tmp, records)
      expect(current)
        .to have_received(:update_settings)
        .with(index_tmp, 'foo' => 'new_bar',
                         'bar' => 'baz',
                         'baz' => 'deadbeef')
      expect(current)
        .to have_received(:move_index)
        .with(index_tmp_name, index_name)
    end
  end
end
