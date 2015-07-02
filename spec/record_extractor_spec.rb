require 'spec_helper'

describe(AlgoliaSearchRecordExtractor) do
  let(:extractor) { AlgoliaSearchRecordExtractor }
  let(:site) do
    get_site
  end
  let(:about_page) do
    extractor.new(site.file_by_name('about.md'))
  end
  let(:test_post) do
    extractor.new(site.file_by_name('2015-07-02-test-post.md'))
  end

  describe 'metadata' do
    it 'gets metadata from page' do
      # Given
      actual = about_page.metadata

      # Then
      expect(actual[:type]).to eq 'page'
      expect(actual[:slug]).to eq 'about'
      expect(actual[:title]).to eq 'About page'
      expect(actual[:url]).to eq '/about.html'
    end

    it 'gets metadata from post' do
      # Given
      actual = test_post.metadata

      # Then
      expect(actual[:type]).to eq 'post'
      expect(actual[:slug]).to eq 'test-post'
      expect(actual[:title]).to eq 'Test post'
      expect(actual[:url]).to eq '/2015/07/02/test-post.html'
      expect(actual[:posted_at]).to eq 1_435_788_000
    end
  end

end
