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
    # Disabling the logs, while still allowing to spy them
    # Jekyll.logger = double('Specific Mock Logger').as_null_object
    @logger = Jekyll.logger.writer
  end

  describe 'type' do
    it 'should recognize a page' do
      # Given
      input = fixture_page

      # When
      actual = input.type

      expect(actual).to eq 'page'
    end

    it 'should recognize a post' do
      # Given
      input = fixture_post

      # When
      actual = input.type

      expect(actual).to eq 'post'
    end

    it 'should recognize a document' do
      # Given
      input = fixture_document

      # When
      actual = input.type

      expect(actual).to eq 'document'
    end
  end

  describe 'url' do
    it 'should use the page url' do
      # Given
      input = fixture_page

      # When
      actual = input.url

      expect(actual).to eq '/about.html'
    end

    it 'should use the post url' do
      # Given
      input = fixture_post

      # When
      actual = input.url

      expect(actual).to eq '/2015/07/02/test-post.html'
    end

    it 'should use the document url' do
      # Given
      input = fixture_document

      # When
      actual = input.url

      expect(actual).to eq '/my-collection/collection-item.html'
    end
  end

  describe 'title' do
    it 'should use the page title' do
      # Given
      input = fixture_page

      # When
      actual = input.title

      expect(actual).to eq 'About page'
    end

    it 'should use the post title' do
      # Given
      input = fixture_post

      # When
      actual = input.title

      expect(actual).to eq 'Test post'
    end

    it 'should use the document title' do
      # Given
      input = fixture_document

      # When
      actual = input.title

      expect(actual).to eq 'Collection Item'
    end
  end

  describe 'slug' do
    it 'should get it for a page' do
      # Given
      input = fixture_page

      # When
      actual = input.slug

      expect(actual).to eq 'about'
    end

    it 'should get it for a post' do
      # Given
      input = fixture_post

      # When
      actual = input.slug

      expect(actual).to eq 'test-post'
    end

    it 'should get it for a document' do
      # Given
      input = fixture_document

      # When
      actual = input.slug

      expect(actual).to eq 'collection-item'
    end

    # if restrict_jekyll_version(more_than: '3.0')
    #   fit 'should not throw a deprecation warning' do
    #     # Given
    #     input = fixture_post

    #     # When
    #     # allow(Jekyll).to receive(:logger) do 
    #     #   double('AAA').as_null_object
    #     # end
    #     # Jekyll.logger = double('BBB').as_null_object
    #     # Jekyll.logger.writer = double('CCC').as_null_object

    #     actual = input.slug


    #     # expect(actual).to eq 'collection-item'
    #   end
    # end
  end

  describe 'tags' do
    it 'should get tags from page' do
      # Given
      input = fixture_page

      # When
      actual = input.tags

      expect(actual).to include('tag', 'another tag')
    end

    it 'should get tags from post' do
      # Given
      input = fixture_post

      # When
      actual = input.tags

      expect(actual).to include('tag', 'another tag')
    end

    it 'should get tags from document' do
      # Given
      input = fixture_document

      # When
      actual = input.tags

      expect(actual).to include('tag', 'another tag')
    end

    it 'should handle custom extended tags' do
      # Given
      extended_tags = [
        double('Extended Tag', to_s: 'extended tag'),
        double('Extended Tag', to_s: 'extended another tag')
      ]
      input = fixture_post

      # Overwrite string tags with more advanced ones
      if restrict_jekyll_version(less_than: '3.0')
        allow(input.file).to receive(:tags) { extended_tags }
      else
        input.file.data['tags'] = extended_tags
      end

      # When
      actual = input.tags

      expect(actual).to include('extended tag', 'extended another tag')
    end
  end

  describe 'date' do
    it 'should get the date as a timestamp for posts' do
      # Given
      input = fixture_post

      # When
      actual = input.date

      # Then
      expect(actual).to eq 1_435_788_000
    end

    it 'should be nil for pages' do
      # Given
      input = fixture_page

      # When
      actual = input.date

      # Then
      expect(actual).to eq nil
    end

    it 'should generate the timestamp relative to the configured timezone' do
      # Given
      site = get_site(timezone: 'America/New_York')
      input = extractor.new(site.file_by_name('test-post.md'))

      # When
      actual = input.date

      # Then
      expect(actual).to eq 1_435_809_600
    end
  end

  describe 'front_matter' do
    it 'should get a hash of all front matter data' do
      # Given
      input = fixture_front_matter

      # When
      actual = input.front_matter

      # Then
      expect(actual[:author]).to eq 'John Doe'
      expect(actual[:custom]).to eq 'foo'
    end

    it 'should remove known keys from the front-matter' do
      # Given
      input = fixture_front_matter

      # When
      actual = input.front_matter

      # Then
      expect(actual[:title]).to eq nil
      expect(actual[:tags]).to eq nil
      expect(actual[:slug]).to eq nil
      expect(actual[:url]).to eq nil
      expect(actual[:date]).to eq nil
      expect(actual[:type]).to eq nil
    end

    it 'should cast keys as symbols' do
      # Given
      input = fixture_front_matter

      # When
      actual = input.front_matter

      # Then
      expect(actual['custom']).to eq nil
      expect(actual[:custom]).to_not eq nil
      expect(actual['author']).to eq nil
      expect(actual[:author]).to_not eq nil
    end
  end

  describe 'extract' do
    it 'should get one item per node' do
      # Given
      input = fixture_only_paragraphs

      # When
      actual = input.extract

      # Then
      expect(actual.size).to eq 6
    end

    it 'should allow overriding the node selector' do
      # Given
      site = get_site(algolia: { 'record_css_selector' => 'div' })
      input = extractor.new(site.file_by_name('only-divs.md'))

      # When
      actual = input.extract

      # Then
      expect(actual.size).to eq 6
    end

    it 'should contain all the basic top level info' do
      # Given
      input = fixture_page
      allow(input).to receive(:date) { 'mock_date' }
      allow(input).to receive(:slug) { 'mock_slug' }
      allow(input).to receive(:tags) { 'mock_tags' }
      allow(input).to receive(:title) { 'mock_title' }
      allow(input).to receive(:url) { 'mock_url' }
      allow(input).to receive(:type) { 'mock_type' }

      # When
      actual = input.extract

      # Then
      expect(actual[0][:date]).to eq 'mock_date'
      expect(actual[0][:slug]).to eq 'mock_slug'
      expect(actual[0][:tags]).to eq 'mock_tags'
      expect(actual[0][:title]).to eq 'mock_title'
      expect(actual[0][:url]).to eq 'mock_url'
      expect(actual[0][:type]).to eq 'mock_type'
    end

    it 'should add node data from extractor' do
      # Given
      input = fixture_page
      allow(input).to receive(:hierarchy_nodes) do
        [
          { name: 'foo' },
          { name: 'bar' }
        ]
      end

      # When
      actual = input.extract

      # Then
      expect(actual[0][:name]).to eq 'foo'
    end

    it 'should not expose the HTML node' do
      # Given
      input = fixture_only_paragraphs

      # When
      actual = input.extract

      # Then
      expect(actual[0][:node]).to eq nil
    end

    it 'should get a complete record' do
      # Given
      input = fixture_page

      # When
      actual = input.extract

      # Then
      # Jekyll auto-generates anchors on heading
      expect(actual[0][:anchor]).to eq 'heading-1'
      # It's a page, so no date
      expect(actual[0][:date]).to eq nil
      # Hierarchy on first level
      expect(actual[0][:hierarchy][:lvl0]).to eq 'Heading 1'
      expect(actual[0][:hierarchy][:lvl1]).to eq nil
      # Node content
      expect(actual[0][:tag_name]).to eq 'p'
      expect(actual[0][:html]).to eq '<p>Text 1</p>'
      expect(actual[0][:text]).to eq 'Text 1'
      # Page
      expect(actual[0][:title]).to eq 'About page'
      expect(actual[0][:slug]).to eq 'about'
      expect(actual[0][:url]).to eq '/about.html'
      # Tags
      expect(actual[0][:tags]).to eq ['tag', 'another tag']
      # Weight
      expect(actual[0][:weight][:heading]).to eq 90
      expect(actual[0][:weight][:position]).to eq 0
    end
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
