require 'spec_helper'

describe(AlgoliaSearchRecordExtractor) do
  let(:extractor) { AlgoliaSearchRecordExtractor }
  let(:site) { get_site }
  let(:fixture_page) { extractor.new(site.file_by_name('about.md')) }
  let(:fixture_post) { extractor.new(site.file_by_name('test-post.md')) }
  let(:fixture_document) do
    extractor.new(site.file_by_name('collection-item.md'))
  end
  let(:fixture_only_paragraphs) do
    extractor.new(site.file_by_name('only-paragraphs.md'))
  end
  let(:fixture_front_matter) do
    extractor.new(site.file_by_name('front_matter.md'))
  end

  before(:each) do
    mock_logger
  end

  describe 'custom_hook_each' do
    it 'should be called on every item' do
      # Given
      input = fixture_page
      allow(input).to receive(:custom_hook_each).and_call_original

      # When
      actual = input.extract

      # Then
      expect(input).to have_received(:custom_hook_each)
        .exactly(actual.size).times
    end

    it 'should let users change the item' do
      # Given
      input = fixture_page
      def input.custom_hook_each(item, _)
        item['foo'] = 'bar'
        item
      end

      # When
      actual = input.extract

      # Then
      expect(actual[0]['foo']).to eq 'bar'
    end

    it 'should let a user remove an item by returning nil' do
      # Given
      input = fixture_page
      def input.custom_hook_each(_, _)
        nil
      end

      # When
      actual = input.extract

      # Then
      expect(actual.size).to eq 0
    end

    it 'should be passed the Nokogiri node as second argument' do
      # Given
      input = fixture_page
      def input.custom_hook_each(item, nokogiri_node)
        item['foo'] = nokogiri_node
        item
      end

      # When
      actual = input.extract

      # Then
      expect(actual[0]['foo']).to be_an(Nokogiri::XML::Element)
    end
  end

  describe 'custom_hook_all' do
    it 'should let the user update the list of records' do
      # Given
      input = fixture_page
      def input.custom_hook_all(_)
        [{
          'foo' => 'bar'
        }]
      end

      # When
      actual = input.extract

      # Then
      expect(actual[0]['foo']).to eq 'bar'
    end
  end
end
