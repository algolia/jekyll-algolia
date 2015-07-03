require 'spec_helper'

describe(AlgoliaSearchRecordExtractor) do
  let(:extractor) { AlgoliaSearchRecordExtractor }
  let(:site) do
    get_site
  end
  let(:test_page) do
    extractor.new(site.file_by_name('about.md'))
  end
  let(:test_post) do
    extractor.new(site.file_by_name('2015-07-02-test-post.md'))
  end
  let(:test_hierarchy) do
    extractor.new(site.file_by_name('hierarchy.md'))
  end
  let(:test_weight) do
    extractor.new(site.file_by_name('weight.md'))
  end

  describe 'metadata' do
    it 'gets metadata from page' do
      # Given
      actual = test_page.metadata

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

  describe 'tags' do
    it 'returns nil if no tag found' do
      expect(test_page.tags).to eq nil
    end
    it 'extract tags from front matter' do
      # Given
      actual = test_post.tags

      # Then
      expect(actual).to include('tag', 'another tag')
    end
  end

  describe 'html_nodes' do
    it 'returns the list of all <p> by default' do
      expect(test_page.html_nodes.size).to eq 6
    end

    it 'allow _config.yml to override the selector' do
      # Given
      site = get_site(algolia: { 'css_selector' => 'p,ul' })
      test_page = extractor.new(site.file_by_name('about.md'))

      expect(test_page.html_nodes.size).to eq 7
    end
  end

  describe 'node_hierarchy' do
    it 'returns the unique parent of a simple element' do
      # Note: First <p> should only have a h1 as hierarchy
      # Given
      nodes = test_hierarchy.html_nodes
      p = nodes[0]

      # When
      actual = test_hierarchy.node_hierarchy(p)

      # Then
      expect(actual).to include(h1: 'H1')
    end

    it 'returns the heading hierarchy of multiple headings' do
      # Note: 4th <p> is inside h3, second h2 and main h1
      # Given
      nodes = test_hierarchy.html_nodes
      p = nodes[3]

      # When
      actual = test_hierarchy.node_hierarchy(p)

      # Then
      expect(actual).to include(h1: 'H1', h2: 'H2B', h3: 'H3')
    end

    it 'works even if heading not on the same level' do
      # Note: The 5th <p> is inside a div
      # Given
      nodes = test_hierarchy.html_nodes
      p = nodes[4]

      # When
      actual = test_hierarchy.node_hierarchy(p)

      # Then
      expect(actual).to include(h1: 'H1', h2: 'H2B', h3: 'H3', h4: 'H4')
    end
  end

  describe 'node_raw_html' do
    it 'returns html including surrounding tags' do
      # Note: 3rd <p> is a real HTML with a custom class
      # Given
      nodes = test_page.html_nodes
      p = nodes[3]

      # When
      actual = test_page.node_raw_html(p)

      # Then
      expect(actual).to eq '<p class="test">Another text 4</p>'
    end
  end

  describe 'node_text' do
    it 'returns inner text with <> escaped' do
      # Note: 4th <p> contains a <code> tag with <>
      # Given
      nodes = test_page.html_nodes
      p = nodes[4]

      # When
      actual = test_page.node_text(p)

      # Then
      expect(actual).to eq 'Another &lt;text&gt; 5'
    end
  end

  describe 'unique_hierarchy' do
    it 'combines title and headings' do
      # Given
      hierarchy = {
        title: 'title',
        h1: 'h1',
        h2: 'h2',
        h3: 'h3',
        h4: 'h4',
        h5: 'h5',
        h6: 'h6'
      }

      # When
      actual = test_page.unique_hierarchy(hierarchy)

      # Then
      expect(actual).to eq 'title > h1 > h2 > h3 > h4 > h5 > h6'
    end

    it 'combines title and headings even with missing elements' do
      # Given
      hierarchy = {
        title: 'title',
        h2: 'h2',
        h4: 'h4',
        h6: 'h6'
      }

      # When
      actual = test_page.unique_hierarchy(hierarchy)

      # Then
      expect(actual).to eq 'title > h2 > h4 > h6'
    end
  end

  describe 'node_css_selector' do
    it 'uses p:nth-of-type' do
      # Given
      nodes = test_page.html_nodes
      p = nodes[2]

      # When
      actual = test_page.node_css_selector(p)

      # Then
      expect(actual).to eq 'p:nth-of-type(3)'
    end

    it 'handles custom <div> markup' do
      # Given
      nodes = test_page.html_nodes
      p = nodes[5]

      # When
      actual = test_page.node_css_selector(p)

      # Then
      expect(actual).to eq 'div:nth-of-type(2) > p'
    end
  end

  fdescribe 'weight' do
    it 'gets the number of words in text also in the title' do
      # Given
      data = {
        title: 'foo bar',
        text: 'Lorem ipsum dolor foo bar, consectetur adipiscing elit'
      }

      # When
      actual = test_page.weight(data)

      # Then
      expect(actual).to eq 2
    end

    it 'gets the number of words in text also in the headings' do
      # Given
      data = {
        title: 'foo',
        h1: 'bar',
        h2: 'baz',
        text: 'Lorem baz dolor foo bar, consectetur adipiscing elit'
      }

      # When
      actual = test_page.weight(data)

      # Then
      expect(actual).to eq 3
    end

    it 'count each word only once' do
      # Given
      data = {
        title: 'foo',
        h1: 'foo foo foo',
        h2: 'bar bar foo bar',
        text: 'foo bar bar bar bar baz foo bar baz'
      }

      # When
      actual = test_page.weight(data)

      # Then
      expect(actual).to eq 2
    end

    it 'is case-insensitive' do
      # Given
      data = {
        title: 'FOO',
        h1: 'bar Bar BAR',
        text: 'foo BAR'
      }

      # When
      actual = test_page.weight(data)

      # Then
      expect(actual).to eq 2

    end

    it 'should only use words, no partial matches' do
      # Given
      data = {
        title: 'foo bar',
        text: 'xxxfooxxx bar'
      }

      # When
      actual = test_page.weight(data)

      # Then
      expect(actual).to eq 1

    end
  end

  # Add a string representation of the hierarchy
end
