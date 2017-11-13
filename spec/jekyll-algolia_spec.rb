# rubocop:disable Metrics/BlockLength
require 'spec_helper'

describe(Jekyll::Algolia) do
  let(:current) { Jekyll::Algolia }

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

  describe '.monkey_patch_site' do
    # Given
    let(:site) { Jekyll::Site.new(Jekyll.configuration) }
    let!(:initial_method) { site.method(:write).source_location }

    # When
    subject do
      current.monkey_patch_site(site)
      site.method(:write).source_location
    end

    # Then
    it 'should change the initial .write method' do
      expect(subject).to_not eq initial_method
    end
  end

  describe 'run' do
    # Prevent the whole process to stop if Algolia config is not available
    before do
      allow(Jekyll::Algolia::Configurator)
        .to receive(:assert_valid_credentials)
        .and_return(true)
    end

    let(:configuration) { Jekyll.configuration }
    let(:jekyll_site) { double('Jekyll::Site', process: nil) }
    before do
      # Making sure all methods are called on the relevant objects
      expect(Jekyll::Site)
        .to receive(:new)
        .with(configuration)
        .and_return(jekyll_site)
      expect(current)
        .to receive(:monkey_patch_site)
        .with(jekyll_site)
      expect(jekyll_site)
        .to receive(:process)
    end

    it { current.init(configuration).run }
  end
end
