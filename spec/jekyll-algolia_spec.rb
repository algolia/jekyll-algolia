# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
require 'spec_helper'

describe(Jekyll::Algolia) do
  let(:configurator) { Jekyll::Algolia::Configurator }
  let(:current) { Jekyll::Algolia }
  let(:extractor) { Jekyll::Algolia::Extractor }
  let(:logger) { Jekyll::Algolia::Logger }
  let(:hooks) { Jekyll::Algolia::Hooks }
  let(:indexer) { Jekyll::Algolia::Indexer }

  # Suppress Jekyll log about not having a config file
  before do
    allow(Jekyll.logger).to receive(:warn)
    allow(logger).to receive(:log)
  end

  describe '.init' do
    let(:config) { Jekyll.configuration }

    context 'with valid Algolia credentials' do
      subject { current.init(config) }

      before do
        allow(configurator)
          .to receive(:assert_valid_credentials)
          .and_return(true)
      end

      it 'should make the site accessible from the outside' do
        expect(subject.site.config).to include(config)
      end
      it 'should check for deprecation warnings' do
        expect(configurator).to receive(:warn_of_deprecated_options)

        current.init(config)
      end
    end

    context 'with invalid Algolia credentials' do
      subject { -> { current.init(config) } }
      before do
        allow(configurator)
          .to receive(:assert_valid_credentials)
          .and_return(false)
      end

      it { is_expected.to raise_error SystemExit }
    end
  end

  describe 'overriding Jekyll::Site#write' do
    # Given
    let(:configuration) { Jekyll.configuration }
    let(:jekyll_site) { Jekyll::Site.new(configuration) }
    let(:algolia_site) { Jekyll::Algolia::Site.new(configuration) }
    let!(:initial_method) { jekyll_site.method(:write).source_location }
    let!(:overridden_method) { algolia_site.method(:write).source_location }

    # Then
    it 'should change the initial .write method' do
      expect(overridden_method).to_not eq initial_method
    end
  end

  describe '.run (mocked build)' do
    # Prevent the whole process to stop if Algolia config is not available
    before do
      allow(Jekyll::Algolia::Configurator)
        .to receive(:assert_valid_credentials)
        .and_return(true)
    end

    let(:configuration) { Jekyll.configuration }
    let(:algolia_site) { double('Jekyll::Algolia::Site', process: nil) }
    before do
      # Making sure all methods are called on the relevant objects
      expect(Jekyll::Algolia::Site)
        .to receive(:new)
        .with(configuration)
        .and_return(algolia_site)
      expect(algolia_site)
        .to receive(:process)
    end

    it { current.init(configuration).run }
  end

  describe '.run (real build)' do
    let(:configuration) do
      Jekyll.configuration(
        source: File.expand_path('./spec/site')
      )
    end
    let(:records_after_hook) { [{ foo: 'bar', objectID: 'AAA' }] }
    let(:record_after_unique_id) { { foo: 'bar', objectID: 'BBB' } }

    before do
      allow(Jekyll.logger).to receive(:info)
      expect(hooks)
        .to receive(:apply_all)
        .and_return(records_after_hook)
      expect(extractor)
        .to receive(:add_unique_object_id)
        .with(records_after_hook[0])
        .and_return(record_after_unique_id)
      expect(indexer)
        .to receive(:run)
        .with([record_after_unique_id])
    end

    it { current.init(configuration).run }
  end
end
# rubocop:enable Metrics/BlockLength
