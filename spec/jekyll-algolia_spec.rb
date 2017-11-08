require 'spec_helper'

describe(Jekyll::Algolia) do
  let(:current) { Jekyll::Algolia }

  # Suppress all Jekyll error messages during tests
  before do
    allow(Jekyll.logger).to receive(:info)
    allow(Jekyll.logger).to receive(:warn)
    allow(Jekyll.logger).to receive(:error)
  end

  describe '.config' do
    # Given
    let(:config) { { 'foo' => 'bar' } }

    # When
    subject { current.init(config) }

    # Then
    it 'should make the config accessible from the outside' do
      expect(subject.config).to include(config)
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
    # Given
    let(:configuration) { {} }
    let(:jekyll_site) { double('Jekyll::Site', process: nil) }
    before { allow(Jekyll::Site).to receive(:new).and_return(jekyll_site) }
    before do
      allow(current).to receive(:monkey_patch_site).and_return(jekyll_site)
    end

    # When
    before do
      current.init(configuration)
      current.run
    end

    # Then
    it 'should have created a new Jekyll::Site with the configuration' do
      expect(Jekyll::Site).to have_received(:new).with(configuration)
    end
    it 'should monkey patch the Jekyll site' do
      expect(current).to have_received(:monkey_patch_site).with(jekyll_site)
    end
    it 'should call .process on the Jekyll site' do
      expect(jekyll_site).to have_received(:process)
    end
  end
end
