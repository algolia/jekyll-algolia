# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable Metrics/BlockLength
describe(Jekyll::Algolia::Indexer) do
  let(:current) { Jekyll::Algolia::Indexer }
  let(:configurator) { Jekyll::Algolia::Configurator }
  let(:logger) { Jekyll::Algolia::Logger }
  let(:error_handler) { Jekyll::Algolia::ErrorHandler }
  let(:progress_bar) { Jekyll::Algolia::ProgressBar }
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
      allow(::Algolia::Index).to receive(:new)
      allow(current).to receive(:set_user_agent)
    end

    describe 'should instanciate Algolia with application id and api_key' do
      before { current.init }

      it do
        expect(::Algolia)
          .to have_received(:init)
          .with(hash_including(
                  application_id: 'app_id',
                  api_key: 'api_key'
                ))
      end
    end

    describe 'should set the user agent' do
      before { current.init }

      it do
        expect(current).to have_received(:set_user_agent)
      end
    end

    describe 'should make the index accessible' do
      let(:index) { double('Algolia::Index') }

      before do
        allow(configurator)
          .to receive(:index_name)
          .and_return('index_name')
        allow(::Algolia::Index)
          .to receive(:new)
          .with('index_name')
          .and_return(index)

        current.init
      end
      it do
        expect(current.index).to eq index
      end
    end

    describe 'should make the index for object ids accessible' do
      let(:index_object_ids) { double('Algolia::Index') }

      before do
        allow(configurator)
          .to receive(:index_object_ids_name)
          .and_return('foo')
        allow(::Algolia::Index)
          .to receive(:new)
          .with('foo')
          .and_return(index_object_ids)

        current.init
      end
      it do
        expect(current.index_object_ids).to eq index_object_ids
      end
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

  describe '.index_exist?' do
    let(:index) { double('Algolia::Index') }

    describe 'when getting settings correctly' do
      subject { current.index_exist?(index) }

      before do
        allow(index).to receive(:get_settings).and_return({})
      end

      it { should eq true }
    end

    describe 'when throwing an error on settings' do
      subject { current.index_exist?(index) }

      before do
        allow(index).to receive(:get_settings).and_raise
      end

      it { should eq false }
    end
  end

  describe '.record_count' do
    let(:index) { double('Algolia::Index') }
    let(:nb_hits) { 12 }

    subject { current.record_count(index) }

    describe 'when index exists' do
      before do
        expect(index)
          .to receive(:search)
          .with(
            '',
            hash_including(
              distinct: false, # To get the correct number of records
              hitsPerPage: 1, # To get a short response
              attributesToRetrieve: 'objectID' # To get a short response
            )
          )
          .and_return('nbHits' => nb_hits)
      end

      it { should eq 12 }
    end

    describe 'when index does not exist' do
      before do
        allow(index).to receive(:search).and_raise
      end

      it { should eq 0 }
    end
  end

  describe '.remote_object_ids_from_main_index' do
    let(:index) { double('Algolia::Index').as_null_object }
    let(:progress_bar_instance) { double('ProgressBarInstance') }

    subject { current.remote_object_ids_from_main_index }

    before do
      allow(current).to receive(:index).and_return(index)
      allow(current).to receive(:record_count)
      allow(progress_bar).to receive(:create).and_return(progress_bar_instance)
      allow(progress_bar_instance).to receive(:increment)

      allow(index)
        .to receive(:browse)
        .and_yield('objectID' => 'foo')
        .and_yield('objectID' => 'bar')
    end

    it 'should return all objectID sorted' do
      should eq %w[bar foo]
    end

    describe 'should grab as many ids as possible' do
      before do
        current.remote_object_ids_from_main_index
      end

      it do
        expect(index)
          .to have_received(:browse)
          .with(
            attributesToRetrieve: 'objectID',
            hitsPerPage: 1000
          )
      end
    end

    describe 'should display a progress bar' do
      before do
        allow(current).to receive(:record_count).and_return(12)
        current.remote_object_ids_from_main_index
      end

      it do
        expect(progress_bar)
          .to have_received(:create)
          .with(hash_including(
                  total: 12
                ))
        expect(progress_bar_instance).to have_received(:increment).twice
      end
    end

    context 'when no index' do
      before do
        allow(index)
          .to receive(:browse)
          .and_raise
      end

      it { should eq [] }
    end
  end

  describe '.remote_object_ids_from_dedicated_index' do
    let(:index) { double('Algolia::Index') }

    subject { current.remote_object_ids_from_dedicated_index }

    before do
      allow(current).to receive(:index_object_ids).and_return(index)

      allow(index)
        .to receive(:browse)
        .and_yield('content' => %w[foo baz])
        .and_yield('content' => ['bar'])
    end

    it 'should return all objectID sorted' do
      should eq %w[bar baz foo]
    end

    describe 'should grab as many ids as possible' do
      before do
        current.remote_object_ids_from_dedicated_index
      end
      it do
        expect(index)
          .to have_received(:browse)
          .with(
            attributesToRetrieve: 'content',
            hitsPerPage: 1000
          )
      end
    end

    context 'when no index' do
      before do
        allow(index)
          .to receive(:browse)
          .and_raise
      end

      it { should eq [] }
    end
  end

  describe '.remote_object_ids' do
    subject { current.remote_object_ids }

    before do
      allow(current)
        .to receive(:remote_object_ids_from_dedicated_index)
        .and_return('dedicated_results')
      allow(current)
        .to receive(:remote_object_ids_from_main_index)
        .and_return('main_results')
      allow(current).to receive(:index_object_ids).and_return('dedicated_index')
      allow(current).to receive(:index).and_return('main_index')
      allow(current)
        .to receive(:record_count)
        .with('main_index')
        .and_return(main_record_count)
      allow(current)
        .to receive(:index_exist?)
        .with('dedicated_index')
        .and_return(dedicated_index_exist)
    end

    describe 'no index is available' do
      let(:main_record_count) { 0 }
      let(:dedicated_index_exist) { false }
      it 'should return an empty list' do
        should eq []
      end
    end

    describe 'only main index is available' do
      let(:main_record_count) { 42 }
      let(:dedicated_index_exist) { false }
      it 'should get objectIds from it' do
        should eq 'main_results'
      end
    end

    describe 'main index is unavailable' do
      let(:main_record_count) { 0 }
      let(:dedicated_index_exist) { true }
      it 'should not use objectIDs from it' do
        should eq []
      end
    end

    describe 'both index are available' do
      let(:main_record_count) { 42 }
      let(:dedicated_index_exist) { true }
      it 'should use objectIDs from the dedicated index' do
        should eq 'dedicated_results'
      end
    end
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
    let(:index) { double('Algolia::Index', name: 'main') }
    let(:index_object_ids) { double('Algolia::Index', name: 'dedicated') }
    let(:has_dedicated_index) { false }
    let(:remote_ids) { %w[bar baz] }
    let(:records) do
      [
        { objectID: 'foo', name: 'foo' },
        { objectID: 'bar', name: 'bar' }
      ]
    end

    before do
      allow(current).to receive(:index).and_return(index)
      allow(current).to receive(:index_object_ids).and_return(index_object_ids)
      allow(current).to receive(:remote_object_ids).and_return(remote_ids)
      allow(current).to receive(:execute_operations)
      allow(current)
        .to receive(:index_exist?)
        .with(index_object_ids)
        .and_return(has_dedicated_index)
    end

    context 'when nothing to update' do
      before do
        allow(current).to receive(:local_object_ids).and_return(local_ids)

        current.update_records(records)
      end
      context 'when records to update and no dedicated index' do
        let(:local_ids) { ['foo'] }
        let(:remote_ids) { [] }
        let(:has_dedicated_index) { false }
        it do
          expect(current)
            .to have_received(:execute_operations)
        end
      end
      context 'when records to update and a dedicated index exist' do
        let(:local_ids) { ['foo'] }
        let(:remote_ids) { [] }
        let(:has_dedicated_index) { true }
        it do
          expect(current)
            .to have_received(:execute_operations)
        end
      end
      context 'when no records to update and no dedicated index' do
        let(:local_ids) { [] }
        let(:remote_ids) { [] }
        let(:has_dedicated_index) { false }
        it do
          expect(current)
            .to have_received(:execute_operations)
        end
      end
      context 'when no records to update but a dedicated index exist' do
        let(:local_ids) { [] }
        let(:remote_ids) { [] }
        let(:has_dedicated_index) { true }
        it do
          expect(current)
            .to_not have_received(:execute_operations)
        end
      end
    end

    context 'batch operations' do
      before do
        current.update_records(records)
      end

      it 'should start with deleting old record' do
        expected = {
          action: 'deleteObject',
          indexName: 'main',
          body: { objectID: 'baz' }
        }

        expect(current)
          .to have_received(:execute_operations) do |operations|
            expect(operations[0]).to eq expected
          end
      end

      it 'should add new items after deleting old ones' do
        expected = {
          action: 'addObject',
          indexName: 'main',
          body: { objectID: 'foo', name: 'foo' }
        }

        expect(current)
          .to have_received(:execute_operations) do |operations|
            expect(operations[1]).to eq expected
          end
      end

      it 'should clear the object id index after updating the record' do
        expected = {
          action: 'clear',
          indexName: 'dedicated'
        }

        expect(current)
          .to have_received(:execute_operations) do |operations|
            expect(operations[2]).to eq expected
          end
      end

      it 'should add new objectIDs to the dedicated index' do
        expected = {
          action: 'addObject',
          indexName: 'dedicated',
          body: { content: %w[bar foo] }
        }

        expect(current)
          .to have_received(:execute_operations) do |operations|
            expect(operations[3]).to eq expected
          end
      end
    end

    context 'when no update to the records' do
      let(:local_ids) { %w[foo bar] }
      let(:remote_ids) { %w[foo bar] }
      before do
        allow(current).to receive(:local_object_ids).and_return(local_ids)

        current.update_records(records)
      end

      context 'do not update the dedicated index if already exist' do
        let(:has_dedicated_index) { true }
        it do
          expect(current).to_not have_received(:execute_operations)
        end
      end

      context 'create the dedicated index if does not yet exist' do
        let(:has_dedicated_index) { false }
        it do
          expect(current)
            .to have_received(:execute_operations) do |operations|
              expect(operations[0]).to include(action: 'clear')
              expect(operations[0]).to include(indexName: 'dedicated')
              expect(operations[1]).to include(action: 'addObject')
              expect(operations[1]).to include(body: { content: %w[foo bar] })
            end
        end
      end
    end

    context 'storing ids by group of 100' do
      let(:records) do
        records = []
        150.times { |i| records << { objectID: "foo-#{i}" } }
        records
      end

      before do
        current.update_records(records)
      end

      it 'should create two records for storing the object IDs' do
        expect(current)
          .to have_received(:execute_operations) do |operations|
            dedicated_index_operations = operations.select do |operation|
              operation[:indexName] == 'dedicated' &&
              operation[:action] == 'addObject'
            end
            expect(dedicated_index_operations.length).to eq 2
          end
      end
    end
  end

  describe '.execute_operations' do
    let(:indexing_batch_size) { 1000 }
    let(:operations) { %w[foo bar] }
    let(:progress_bar_instance) { double('ProgressBarInstance') }

    before do
      allow(::Algolia).to receive(:batch!)
      allow(progress_bar).to receive(:create).and_return(progress_bar_instance)
      allow(progress_bar_instance).to receive(:increment)
      allow(configurator)
        .to receive(:algolia)
        .with('indexing_batch_size')
        .and_return(indexing_batch_size)
    end

    context 'when running in dry run mode' do
      let(:dry_run) { true }

      before { current.execute_operations(operations) }

      it do
        expect(::Algolia).to_not have_received(:batch!)
      end
    end

    context 'when running an empty set of operations' do
      let(:operations) { [] }

      before { current.execute_operations(operations) }

      it do
        expect(::Algolia).to_not have_received(:batch!)
      end
    end

    context 'split in smaller batches if too many operations' do
      let(:indexing_batch_size) { 1 }

      before { current.execute_operations(operations) }

      it do
        expect(::Algolia)
          .to have_received(:batch!)
          .ordered
          .with(['foo'])
        expect(::Algolia)
          .to have_received(:batch!)
          .ordered
          .with(['bar'])
      end
    end

    context 'progress bar' do
      before { current.execute_operations(operations) }

      describe 'should not create it if only one batch' do
        it do
          expect(progress_bar).to_not have_received(:create)
          expect(progress_bar_instance).to_not have_received(:increment)
        end
      end
      describe 'should create it if several batches' do
        let(:indexing_batch_size) { 1 }
        it do
          expect(progress_bar).to have_received(:create)
          expect(progress_bar_instance).to have_received(:increment).twice
        end
      end
    end

    context 'dispatch the error to the error handler' do
      before do
        allow(::Algolia).to receive(:batch!).and_raise
        allow(error_handler).to receive(:stop)

        current.execute_operations(operations)
      end

      describe 'when only one slice' do
        it do
          expect(error_handler)
            .to have_received(:stop)
            .with(RuntimeError, operations: operations)
        end
      end

      describe 'when split in several slices' do
        let(:indexing_batch_size) { 1 }
        let(:operations) { %w[foo bar] }
        it do
          expect(error_handler)
            .to have_received(:stop)
            .with(RuntimeError, operations: ['foo'])
        end
      end
    end
  end

  describe '.update_settings' do
    let(:pluginVersion) { nil }
    let(:diff_keys) { nil }
    let(:force_settings) { nil }
    let(:settings) { Jekyll::Algolia::Configurator::ALGOLIA_DEFAULTS['settings'].merge({}) }

    before do
      stub_const('Jekyll::Algolia::VERSION', pluginVersion)
      allow(utils).to receive(:diff_keys).and_return(diff_keys)
      allow(configurator)
        .to receive(:force_settings?)
        .and_return(force_settings)
      allow(configurator)
        .to receive(:settings)
        .and_return(settings)
      allow(current).to receive(:set_settings)
      allow(current).to receive(:warn_of_manual_dashboard_editing)
      allow(current).to receive(:local_setting_id).and_return(local_setting_id)
      allow(current).to receive(:remote_settings).and_return(remote_settings)
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

    describe 'should always update if --force-settings' do
      let(:local_setting_id) { 'foo' }
      let(:remote_settings) { { 'userData' => { 'settingID' => 'foo' } } }
      let(:force_settings) { true }
      it do
        expect(current)
          .to have_received(:set_settings)
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
            hash_including(
              'userData' => hash_including('settingID' => 'foo')
            )
          )
      end
    end

    describe 'should update settings with new version' do
      let(:local_setting_id) { 'foo' }
      let(:remote_settings) { { 'userData' => { 'settingID' => 'bar' } } }
      let(:pluginVersion) { 'pluginVersion' }
      it do
        expect(current)
          .to have_received(:set_settings)
          .with(
            hash_including(
              'userData' => hash_including('pluginVersion' => 'pluginVersion')
            )
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

    describe 'should not update settings if user configured false' do
      let(:local_setting_id) { 'foo' }
      let(:settings) { {} }
      let(:remote_settings) { {} }
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
      allow(configurator).to receive(:index_name).and_return('my_index')
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
            'W:      - baz',
          index_name: 'my_index'
        )
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
          .with(records)
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
