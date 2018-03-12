# frozen_string_literal: true

require_relative './spec_helper'

# Note: Those tests will delete and recreate the index several times, deleting
# any records in it, in order to test the settings.
# Be careful if you're actually testing the record content in the same test
# suite. It is recommended to run thoses tests after the main ones.

# rubocop:disable Metrics/BlockLength
describe('updating settings') do
  let(:configurator) { Jekyll::Algolia::Configurator }
  let(:logger) { Jekyll::Algolia::Logger }
  let(:indexer) { Jekyll::Algolia::Indexer.init }
  before(:all) do
    # Requesting the index from outside of the Jekyll plugin
    @index = Algolia::Index.new(ENV['ALGOLIA_INDEX_NAME'])

    # We keep a reference to what default index settings look like so we can
    # revert the index to this state. It will allow us to create an empty index
    tmp_index = Algolia::Index.new("#{ENV['ALGOLIA_INDEX_NAME']}_tmp")
    tmp_index.add_objects!([{ foo: 'bar' }])
    @default_settings = tmp_index.get_settings
    tmp_index.delete_index!
  end

  before do
    @index.delete_index!

    # Hide logs
    allow(logger).to receive(:log)
  end

  describe 'initial push' do
    subject { @index.get_settings['userData'] }

    let(:local_setting_id) { 'foo' }

    before do
      allow(indexer).to receive(:local_setting_id).and_return(local_setting_id)
    end

    context 'with no index at all' do
      before do
        indexer.update_settings
      end
      it { should include('settingID' => 'foo') }
    end

    context 'with an empty index' do
      before do
        # We create an index
        @index.set_settings!(@default_settings)
        indexer.update_settings
      end
      it { should include('settingID' => 'foo') }
    end

    context 'with an index, but no settingID' do
      before do
        @index.set_settings!(userData: { settingID: nil })
        indexer.update_settings
      end
      it { should include('settingID' => 'foo') }
    end
  end

  describe 'index already set' do
    before do
      @index.set_settings!(userData: { settingID: remote_setting_id })

      allow(indexer).to receive(:local_setting_id).and_return(local_setting_id)
      allow(indexer).to receive(:set_settings).and_call_original
    end

    context 'with same settingID' do
      let(:local_setting_id) { 'foo' }
      let(:remote_setting_id) { 'foo' }

      before { indexer.update_settings }

      it 'should not update the settings' do
        expect(indexer).to_not have_received(:set_settings)
        remote_data = @index.get_settings['userData']
        expect(remote_data).to include('settingID' => 'foo')
      end
    end

    context 'with different settingID' do
      let(:local_setting_id) { 'bar' }
      let(:remote_setting_id) { 'foo' }

      before { indexer.update_settings }

      it 'should update the settings' do
        expect(indexer).to have_received(:set_settings)
        remote_data = @index.get_settings['userData']
        expect(remote_data).to include('settingID' => 'bar')
      end
    end
  end

  describe 'local settings updated' do
    # Running it once to set it
    before { indexer.update_settings }

    context 'when no config is updated' do
      it 'should keep the same settingID' do
        # Remote settingID before
        remote_setting_id_before = @index.get_settings['userData']['settingID']

        # Doing nothing...

        # Running again
        indexer.update_settings

        remote_setting_id_after = @index.get_settings['userData']['settingID']
        expect(remote_setting_id_before).to eq remote_setting_id_after
      end
    end

    context 'with updated index settings' do
      it 'should change the settingID' do
        # Remote settingID before
        remote_setting_id_before = @index.get_settings['userData']['settingID']

        # Updating _config.yml config
        current_settings = configurator.settings
        current_settings['attributeForDistinct'] = 'foobar'
        allow(configurator)
          .to receive(:settings)
          .and_return(current_settings)

        # Running again
        indexer.update_settings

        remote_setting_id_after = @index.get_settings['userData']['settingID']
        expect(remote_setting_id_before).to_not eq remote_setting_id_after
      end
    end
  end

  describe 'manual changes in the dashboard' do
    before do
      indexer.update_settings

      allow(indexer).to receive(:set_settings).and_call_original
    end

    context 'changed a setting changed by the plugin' do
      before do
        # Change one bit of settings
        settings = @index.get_settings
        new_custom_ranking = settings['customRanking'] + ['asc(foo)']
        settings['customRanking'] = new_custom_ranking
        @index.set_settings!(settings)

        expect(indexer)
          .to receive(:warn_of_manual_dashboard_editing)
          .with('customRanking' => new_custom_ranking)

        indexer.update_settings
      end
      it do
        expect(indexer).to_not have_received(:set_settings)
      end
    end

    context 'changed a setting unrelated to the plugin' do
      before do
        # Change one bit of settings
        settings = @index.get_settings
        settings['minWordSizefor1Typo'] = 5
        @index.set_settings!(settings)

        allow(indexer)
          .to receive(:warn_of_manual_dashboard_editing)

        indexer.update_settings
      end
      it do
        expect(indexer).to_not have_received(:set_settings)
        expect(indexer).to_not have_received(:warn_of_manual_dashboard_editing)
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
