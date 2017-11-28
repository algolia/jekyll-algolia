# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
require 'spec_helper'

describe(Jekyll::Algolia) do
  let(:current) { Jekyll::Algolia }
  let(:indexer) { Jekyll::Algolia::Indexer }

  # Suppress Jekyll log about not having a config file
  before do
    allow(Jekyll.logger).to receive(:warn)
  end

  describe '.init' do
    let(:config) { Jekyll.configuration }

    context 'with valid Algolia credentials' do
      subject { current.init(config) }

      before do
        allow(Jekyll::Algolia::Configurator)
          .to receive(:assert_valid_credentials)
          .and_return(true)
      end

      it 'should make the config accessible from the outside' do
        expect(subject.config).to include(config)
      end
      it 'should make the site accessible from the outside' do
        expect(subject.site.config).to include(config)
      end
    end

    context 'with invalid Algolia credentials' do
      subject { -> { current.init(config) } }
      before do
        allow(Jekyll::Algolia::Configurator)
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
    # The actual indexing should be done on the list of records + one added
    # through the custom hook
    RSpec::Matchers.define :a_custom_record_added_at_the_end do
      match do |actual|
        actual[-1][:name] == 'Last one'
      end
    end

    before do
      allow(Jekyll.logger).to receive(:info)
      expect(indexer).to receive(:run).with(a_custom_record_added_at_the_end)
    end

    it { current.init(configuration).run }
  end
end
