# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable Metrics/BlockLength
describe(Jekyll::Algolia::Indexer) do
  let(:current) { Jekyll::Algolia::Indexer }
  let(:configurator) { Jekyll::Algolia::Configurator }
  let(:logger) { Jekyll::Algolia::Logger }
  let(:error_handler) { Jekyll::Algolia::ErrorHandler }
  let(:utils) { Jekyll::Algolia::Utils }
  let(:html_extractor) { AlgoliaHTMLExtractor }
  let(:dry_run) { false }
  before { allow(configurator).to receive(:dry_run?).and_return(dry_run) }
  before { allow(logger).to receive(:log) }

  describe '.init' do
    before do
      allow(configurator).to receive(:application_id).and_return('app_id')
      allow(configurator).to receive(:api_key).and_return('api_key')
      allow(::Algolia).to receive(:init)
      allow(::Algolia::Index)
        .to receive(:new)
        .and_return(double('Algolia::Index', name: 'index_name'))
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
    it 'should make the index accessible' do
      expect(current.index.name).to eq 'index_name'
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

  describe '.remote_object_ids' do
    subject { current.remote_object_ids }

    let(:index) { double('Algolia::Index').as_null_object }

    before do
      allow(current).to receive(:index).and_return(index)
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

  describe '.update_records' do
    let(:index) { double('Algolia::Index', name: 'my_index') }
    let(:old_records_ids) { %w[abc] }
    let(:new_records) { [{ 'objectID' => 'def' }] }
    let(:indexing_batch_size) { 1000 }

    before { allow(::Algolia).to receive(:batch!) }
    before do
      allow(current).to receive(:index).and_return(index)
      allow(configurator)
        .to receive(:algolia)
        .with('indexing_batch_size')
        .and_return(indexing_batch_size)
    end
    before { current.update_records(old_records_ids, new_records) }

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

    it 'should batch all operations (deletions first)' do
      expect(::Algolia)
        .to have_received(:batch!)
        .with([
                {
                  action: 'deleteObject',
                  indexName: 'my_index',
                  body: { objectID: 'abc' }
                },
                {
                  action: 'addObject',
                  indexName: 'my_index',
                  body: { 'objectID' => 'def' }
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
                    action: 'deleteObject',
                    indexName: 'my_index',
                    body: { objectID: 'abc' }
                  }
                ])
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
      end
    end
  end

  describe '.run' do
    let(:records) { [{ objectID: 'foo' }, { objectID: 'bar' }] }
    let(:remote_ids) { %w[foo baz] }
    let(:index_name) { 'my_index' }
    let(:index) { double('Algolia::Index', name: index_name) }
    before do
      allow(current).to receive(:init)
      allow(current).to receive(:index).and_return(index)
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
      end
      it do
        expect(current)
          .to have_received(:update_records)
          .with(['baz'], [{ objectID: 'bar' }])
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

  describe '.update_settings' do
    let(:diff_keys) { nil }

    before do
      allow(current).to receive(:set_settings)
      allow(current).to receive(:warn_of_manual_dashboard_editing)
      allow(current).to receive(:local_setting_id).and_return(local_setting_id)
      allow(current).to receive(:remote_settings).and_return(remote_settings)
      allow(utils).to receive(:diff_keys).and_return(diff_keys)
      allow(current)
        .to receive(:index)
        .and_return(double('Algolia::index', name: 'my_index'))

      current.update_settings
    end

    describe 'should do nothing if same settings both locally and remote' do
      let(:local_setting_id) { 'foo' }
      let(:remote_settings) { { 'userData' => { 'settingID' => 'foo' } } }
      it { expect(current).to_not have_received(:set_settings) }
      it do
        expect(current).to_not have_received(:warn_of_manual_dashboard_editing)
      end
      context 'with remote settings manually edited' do
        let(:diff_keys) { { 'foo' => 'bar' } }
        it do
          expect(current)
            .to have_received(:warn_of_manual_dashboard_editing)
            .with('foo' => 'bar')
        end
      end
    end

    describe 'should update settings if no remote settingID' do
      let(:local_setting_id) { 'foo' }
      let(:remote_settings) { { 'userData' => {} } }
      it do
        expect(current)
          .to have_received(:set_settings)
      end
    end

    describe 'should update settings if no remote userData' do
      let(:local_setting_id) { 'foo' }
      let(:remote_settings) { {} }
      it do
        expect(current).to have_received(:set_settings)
      end
    end

    describe 'should update settings if no remote settings' do
      let(:local_setting_id) { 'foo' }
      let(:remote_settings) { nil }
      it do
        expect(current).to have_received(:set_settings)
      end
    end

    describe 'should update settings if local and remote id are different' do
      let(:local_setting_id) { 'foo' }
      let(:remote_settings) { { 'userData' => { 'settingID' => 'bar' } } }
      it do
        expect(current).to have_received(:set_settings)
      end
    end

    describe 'should update settings with new settingID' do
      let(:local_setting_id) { 'foo' }
      let(:remote_settings) { { 'userData' => { 'settingID' => 'bar' } } }
      it do
        expect(current)
          .to have_received(:set_settings)
          .with(
            hash_including('userData' => { 'settingID' => 'foo' })
          )
      end
    end

    describe 'should not update in dry run' do
      let(:local_setting_id) { 'foo' }
      let(:remote_settings) { { 'userData' => { 'settingID' => 'bar' } } }
      let(:dry_run) { true }
      it do
        expect(current).to_not have_received(:set_settings)
      end
    end
  end

  describe '.local_setting_id' do
    subject { current.local_setting_id }

    before do
      expect(configurator).to receive(:settings).and_return(settings)
    end

    describe do
      let(:settings) { { 'foo' => 'bar' } }
      it { should eq '06ad47d8e64bd28de537b62ff85357c4' }
    end

    describe do
      let(:settings) { { 'foo' => 'baz' } }
      it { should_not eq '06ad47d8e64bd28de537b62ff85357c4' }
    end

    describe do
      let(:settings) do
        { 'foo' => 'bar', 'userData' => { 'settingID': 'foo' } }
      end
      it { should eq '06ad47d8e64bd28de537b62ff85357c4' }
    end
  end

  describe '.remote_settings' do
    let(:index) { double('Algolia::Index') }

    before do
      allow(current).to receive(:index).and_return(index)
    end

    context 'with actual index' do
      subject { current.remote_settings }

      before do
        allow(index).to receive(:get_settings).and_return('settings')
      end

      it { should eq 'settings' }
    end

    context 'with API error' do
      subject { current.remote_settings }

      before do
        allow(index).to receive(:get_settings).and_raise
      end

      it { is_expected.to eq nil }
    end
  end

  describe '.set_settings' do
    let(:index) { double('Algolia::Index') }
    let(:settings) { 'settings' }

    before do
      allow(current).to receive(:index).and_return(index)
    end

    describe 'with valid settings' do
      before do
        allow(index).to receive(:set_settings!)
        current.set_settings(settings)
      end
      it do
        expect(index).to have_received(:set_settings!).with(settings)
      end
    end

    describe 'with invalid settings' do
      before do
        allow(index).to receive(:set_settings!).and_raise
        allow(error_handler).to receive(:stop)

        current.set_settings(settings)
      end
      it do
        expect(error_handler)
          .to have_received(:stop)
          .with(RuntimeError, settings: settings)
      end
    end
  end

  describe '.warn_of_manual_dashboard_editing' do
    let(:changed_keys) do
      {
        'distinct' => false,
        'customRanking' => %w[foo bar baz]
      }
    end

    before do
      allow(logger).to receive(:known_message)
      current.warn_of_manual_dashboard_editing(changed_keys)
    end

    it do
      expect(logger)
        .to have_received(:known_message)
        .with(
          'settings_manually_edited',
          settings:
            "W:    distinct: false\n"\
            "W:    customRanking:\n"\
            "W:      - foo\n"\
            "W:      - bar\n"\
            'W:      - baz'\
        )
    end
  end
end
# rubocop:enable Metrics/BlockLength
