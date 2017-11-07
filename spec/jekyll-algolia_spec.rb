require 'spec_helper'

describe(Jekyll::Algolia) do
  let(:subject) { Jekyll::Algolia }

  # Suppress all Jekyll error messages during tests
  before(:each) do
    allow(Jekyll.logger).to receive(:info)
    allow(Jekyll.logger).to receive(:warn)
    allow(Jekyll.logger).to receive(:error)
  end

  describe 'config' do
    it 'should set the @config accessible from outside' do
      # Given
      input = { 'foo' => 'bar' }

      # When
      subject.init(input)

      # Then
      expect(subject.config).to include(input)
    end
  end

  describe 'monkey_patch_site' do
    it 'should change the site write method' do
      # Given
      site = Jekyll::Site.new(Jekyll.configuration)
      initial_method = site.method(:write).source_location

      # When
      subject.monkey_patch_site(site)

      # Then
      actual = site.method(:write).source_location
      expect(actual).not_to eq initial_method
    end
  end

  describe 'run' do
    mock_site = nil
    before(:each) do
      # We mock Jekyll::Site.new so it always returns an object that answers to
      # .process
      mock_site = double('Jekyll::Site', process: nil)
      allow(Jekyll::Site).to receive(:new).and_return(mock_site)
    end
    it 'should create a new site with the initialized config' do
      # Given
      input = Jekyll.configuration

      # Then
      expect(Jekyll::Site).to receive(:new).with(input)

      # When
      subject.init(input)
      subject.run
    end
    it 'should monkey patch the created site' do
      # Given
      input = Jekyll.configuration

      # Then
      expect(Jekyll::Algolia).to receive(:monkey_patch_site).with(mock_site)

      # When
      subject.init(input)
      subject.run
    end
    it 'should call process on the created site' do
      # Given
      input = Jekyll.configuration

      # Then
      expect(mock_site).to receive(:process)

      # When
      subject.init(input)
      subject.run
    end
  end
end
