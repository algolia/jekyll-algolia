# rubocop:disable Metrics/BlockLength
require 'spec_helper'

describe(Jekyll::Algolia::Indexer) do
  let(:current) { Jekyll::Algolia::Indexer }
  let(:configurator) { Jekyll::Algolia::Configurator }

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

  describe '.update_settings' do
    let(:index) { double('Algolia::Index', set_settings: nil) }
    let(:settings) { { 'foo' => 'bar' } }
    before { current.update_settings(index, settings) }

    it do
      expect(index).to have_received(:set_settings).with(settings)
    end
  end
end
