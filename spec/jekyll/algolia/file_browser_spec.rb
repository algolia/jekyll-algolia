# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
require 'spec_helper'

describe(Jekyll::Algolia::FileBrowser) do
  let(:current) { Jekyll::Algolia::FileBrowser }
  let(:configurator) { Jekyll::Algolia::Configurator }
  let(:site) { init_new_jekyll_site }

  # Suppress Jekyll logging
  before do
    allow(Jekyll.logger).to receive(:info)
    allow(Jekyll.logger).to receive(:warn)
  end
  # Do not exit on wrong Algolia configuration
  before do
    allow(Jekyll::Algolia::Configurator)
      .to receive(:assert_valid_credentials)
      .and_return(true)
  end

  describe '.absolute_path' do
    subject { current.absolute_path(file) }

    let(:file) { double('Jekyll::File', path: path) }

    context 'with an absolute path' do
      let(:path) { '/absolute/path/to/file.ext' }
      it { should eq path }
    end
    context 'with an relative path' do
      let(:path) { 'file.ext' }
      let(:source) { '/path/to/jekyll/source/' }
      before do
        allow(configurator).to receive(:get)
        expect(configurator).to receive(:get).with('source').and_return(source)
      end
      it { should eq '/path/to/jekyll/source/file.ext' }
    end
    context 'with a relative source' do
      let(:path) { 'file.ext' }
      let(:source) { '.' }
      before do
        allow(configurator).to receive(:get)
        expect(configurator).to receive(:get).with('source').and_return(source)
      end
      it { should eq "#{Dir.pwd}/file.ext" }
    end
  end

  describe '.relative_path' do
    subject { current.relative_path(file) }

    let(:file) { double('Jekyll::File', path: path) }
    let(:source) { '/path/to/jekyll/' }

    before do
      allow(configurator).to receive(:get).with('source').and_return(source)
    end

    context 'with an absolute path' do
      let(:path) { '/path/to/jekyll/file.ext' }
      it { should eq 'file.ext' }
    end
    context 'with an relative path path' do
      let(:path) { 'file.ext' }
      it { should eq path }
    end
  end

  describe '.indexable?' do
    subject { current.indexable?(file) }

    context 'with a static asset' do
      let(:file) { site.__find_file('png.png') }
      it { should eq false }
    end
    context 'with a pagination page' do
      let(:file) { site.__find_file('blog/pages/2/index.html') }
      it { should eq false }
    end
    context 'with a file excluded by a hook' do
      let(:file) { site.__find_file('excluded-from-hook.html') }
      it { should eq false }
    end
    context 'with a file not in the allowed extensions' do
      let(:file) { site.__find_file('dhtml.dhtml') }
      it { should eq false }
    end

    context 'with a regular markdown file' do
      let(:file) { site.__find_file('markdown.markdown') }
      it { should eq true }
    end
    context 'with a regular HTML file' do
      let(:file) { site.__find_file('html.html') }
      it { should eq true }
    end
  end

  describe '.static_file?' do
    subject { current.static_file?(file) }

    context 'with a static file' do
      let(:file) { site.__find_file('ring.png') }
      it { should eq true }
    end
    context 'with an html page' do
      let(:file) { site.__find_file('html.html') }
      it { should eq false }
    end
  end

  describe '.pagination_page?' do
    subject { current.pagination_page?(file) }

    context 'with a custom pagination page' do
      let(:file) { site.__find_file('blog/pages/2/index.html') }
      it { should eq true }
    end

    context 'with a pagination page starting with no forward slash' do
      let(:file) { double('File', path: 'blog/pages/2/index.html') }
      it { should eq true }
    end

    context 'with a pagination page starting with no a forward slash' do
      let(:file) { double('File', path: '/blog/pages/2/index.html') }
      it { should eq true }
    end
  end

  describe '.allowed_extension?' do
    subject { current.allowed_extension?(file) }

    context 'with default config' do
      describe 'should accept html files' do
        let(:file) { site.__find_file('html.html') }
        it { should eq true }
      end
      describe 'should accept .markdown files' do
        let(:file) { site.__find_file('markdown.markdown') }
        it { should eq true }
      end
      describe 'should accept .mkdown files' do
        let(:file) { site.__find_file('mkdown.mkdown') }
        it { should eq true }
      end
      describe 'should accept .mkdn files' do
        let(:file) { site.__find_file('mkdn.mkdn') }
        it { should eq true }
      end
      describe 'should accept .mkd files' do
        let(:file) { site.__find_file('mkd.mkd') }
        it { should eq true }
      end
      describe 'should accept .md files' do
        let(:file) { site.__find_file('md.md') }
        it { should eq true }
      end
    end

    context 'with custom config' do
      before do
        allow(configurator)
          .to receive(:algolia)
        allow(configurator)
          .to receive(:algolia)
          .with('extensions_to_index')
          .and_return('html,dhtml')
      end

      describe 'should accept html' do
        let(:file) { site.__find_file('html.html') }
        it { should eq true }
      end
      describe 'should accept dhtml' do
        let(:file) { site.__find_file('dhtml.dhtml') }
        it { should eq true }
      end
      describe 'should reject other files' do
        let(:file) { site.__find_file('md.md') }
        it { should eq false }
      end
    end
  end

  describe '.type' do
    subject { current.type(file) }

    context 'with a markdown page' do
      let(:file) { site.__find_file('about.md') }
      it { should eq 'page' }
    end
    context 'with an HTML page' do
      let(:file) { site.__find_file('html.html') }
      it { should eq 'page' }
    end
    context 'with a post' do
      let(:file) { site.__find_file('-test-post.md') }
      it { should eq 'post' }
    end
    context 'with a collection element' do
      let(:file) { site.__find_file('collection-item.html') }
      it { should eq 'document' }
    end
  end

  describe '.url' do
    subject { current.url(file) }

    context 'with a page' do
      let(:file) { site.__find_file('about.md') }
      it { should eq '/about.html' }
    end
    context 'with a post' do
      let(:file) { site.__find_file('-test-post-again.md') }
      it { should eq '/2015/07/03/test-post-again.html' }
    end
    context 'with a collection element' do
      let(:file) { site.__find_file('_my-collection/collection-item.html') }
      it { should eq '/my-collection/collection-item.html' }
    end
  end

  describe '.date' do
    subject { current.date(file) }

    context 'with a page in the root' do
      let(:file) { site.__find_file('about.md') }
      it { should eq nil }
    end
    context 'with a collection element with a date set in front-matter' do
      let(:file) { site.__find_file('_my-collection/collection-item.html') }
      it { should eq 452_469_600 }
    end
    context 'with a collection element with no date' do
      let(:file) { site.__find_file('_my-collection/sample-item.md') }
      it { should eq nil }
    end
    context 'with a post' do
      let(:file) { site.__find_file('_posts/2015-07-02-test-post.md') }
      it { should eq 1_435_788_000 }
    end

    context 'with a custom timezone' do
      let(:site) { init_new_jekyll_site(timezone: 'America/New_York') }
      let(:file) { site.__find_file('_posts/2015-07-02-test-post.md') }
      it { should eq 1_435_809_600 }
    end
  end

  describe '.excerpt_raw' do
    let(:file) { double('File', data: { 'excerpt' => excerpt }) }
    let(:excerpt) { double('Excerpt') }

    context 'valid excerpt' do
      subject { current.excerpt_raw(file) }
      before do
        allow(excerpt).to receive(:to_s).and_return('foo')
      end

      it { should eq 'foo' }
    end

    context 'invalid excerpt' do
      subject { current.excerpt_raw(file) }
      before do
        allow(excerpt).to receive(:to_s).and_raise
      end

      it { should eq nil }
    end
  end

  describe '.excerpt_html' do
    let(:expected) do
      '<p>This is the first paragraph. It is especially long because we '\
      'want it to wrap on two lines.</p>'
    end

    subject { current.excerpt_html(file) }

    context 'with real files' do
      context 'with a page' do
        let(:file) { site.__find_file('excerpt.md') }
        it { should eq nil }
      end
      context 'with a post' do
        let(:file) { site.__find_file('-post-with-excerpt.md') }
        it { should eq expected }
      end
      context 'with a collection' do
        let(:file) { site.__find_file('collection-item-with-excerpt.md') }
        it { should eq expected }
      end
    end

    context 'with mock excerpt' do
      let(:file) { double('File') }
      before do
        allow(current).to receive(:excerpt_raw).and_return(raw)
      end

      describe 'should return the excerpt as returned by Jekyll' do
        let(:raw) { 'raw' }
        it { should eq 'raw' }
      end
      describe 'empty excerpt are treated as nil' do
        let(:raw) { '' }
        it { should eq nil }
      end
      describe do
        let(:raw) { nil }
        it { should eq nil }
      end
    end
  end

  describe '.excerpt_txt' do
    let(:expected) do
      'This is the first paragraph. It is especially long because we want '\
      'it to wrap on two lines.'
    end
    subject { current.excerpt_text(file) }

    context 'with a page' do
      let(:file) { site.__find_file('excerpt.md') }
      it { should eq nil }
    end
    context 'with a post' do
      let(:file) { site.__find_file('-post-with-excerpt.md') }
      it { should eq expected }
    end
    context 'with a collection' do
      let(:file) { site.__find_file('collection-item-with-excerpt.md') }
      it { should eq expected }
    end
  end

  describe '.slug' do
    subject { current.slug(file) }

    context 'with a post' do
      let(:file) { site.__find_file('-test-post-again.md') }
      it { should eq 'test-post-again' }
    end
    context 'with a collection element' do
      let(:file) { site.__find_file('_my-collection/collection-item.html') }
      it { should eq 'collection-item' }
    end
    context 'with a page' do
      let(:file) { site.__find_file('authors.html') }
      it { should eq 'authors' }
    end
    context 'with a page with mixed case' do
      let(:file) { site.__find_file('MIXed-CaSe.md') }
      it { should eq 'mixed-case' }
    end
  end

  describe '.collection' do
    subject { current.collection(file) }

    context 'with a page' do
      let(:file) { site.__find_file('authors.html') }
      it { should eq nil }
    end
    context 'with a post' do
      let(:file) { site.__find_file('-test-post-again.md') }
      it { should eq nil }
    end
    context 'with a collection element' do
      let(:file) { site.__find_file('_my-collection/collection-item.html') }
      it { should eq 'my-collection' }
    end
  end

  describe '.raw_data' do
    subject { current.raw_data(file) }

    context 'with a page' do
      let(:file) { site.__find_file('about.md') }
      it do
        should include(title: 'About')
        should include(custom1: 'foo')
        should include(custom2: 'bar')
        should include(customList: %w[foo bar])
      end
    end
    context 'with a post' do
      let(:file) { site.__find_file('-test-post.md') }
      it do
        should include(title: 'Test post')
        should include(categories: %w[foo bar])
        should include(tags: ['tag', 'another tag'])
        should include(draft: false)
        should include(ext: '.md')
      end
    end
    context 'with a collection item' do
      let(:file) { site.__find_file('collection-item.html') }
      it do
        should include(title: 'Collection Item')
        should include(categories: [])
        should include(tags: [])
        should include(draft: false)
        should include(ext: '.html')
      end
    end

    describe 'should not have modified the inner data' do
      let(:file) { site.__find_file('html.html') }
      let!(:data_before) { file.data }
      it { expect(file.data).to eq data_before }
    end
    describe 'should not contain keys where we have defined getters' do
      let(:file) { site.__find_file('html.html') }
      it do
        should_not include(:slug)
        should_not include(:type)
        should_not include(:url)
        should_not include(:date)
      end
    end
    describe 'should not contain the excerpt' do
      let(:file) { site.__find_file('html.html') }
      it { should_not include(:excerpt) }
    end

    context 'jekyll-asciidoc compatibility' do
      context do
        let(:data) { { 'document' => 'foo' } }
        let(:file) { double('Jekyll::File', data: data) }
        it do
          should include(document: 'foo')
        end
      end
      context do
        let(:data) { { 'document' => Asciidoctor::Document.new } }
        let(:file) { double('Jekyll::File', data: data) }
        before do
          stub_const('Asciidoctor::Document', Class.new)
        end
        it do
          should_not include(:document)
        end
      end
    end
  end

  describe '.metadata' do
    subject { current.metadata(file) }

    context 'with mocked data' do
      let(:file) { nil }
      before do
        allow(current).to receive(:collection).and_return('collection')
        allow(current).to receive(:date).and_return('date')
        allow(current).to receive(:excerpt_html).and_return('excerpt_html')
        allow(current).to receive(:excerpt_text).and_return('excerpt_text')
        allow(current).to receive(:slug).and_return('slug')
        allow(current).to receive(:type).and_return('type')
        allow(current).to receive(:url).and_return('url')

        allow(current).to receive(:raw_data).and_return(foo: 'foo', bar: 'bar')
      end
      describe 'should contain all custom data' do
        it { should include(collection: 'collection') }
        it { should include(date: 'date') }
        it { should include(excerpt_html: 'excerpt_html') }
        it { should include(excerpt_text: 'excerpt_text') }
        it { should include(slug: 'slug') }
        it { should include(type: 'type') }
        it { should include(url: 'url') }
      end
      describe 'should contain custom metadata' do
        it { should include(foo: 'foo') }
        it { should include(bar: 'bar') }
      end
      context 'with nil keys' do
        before do
          allow(current).to receive(:url).and_return(nil)
          allow(current).to receive(:raw_data).and_return(foo: nil, bar: 'bar')
        end
        it { should_not include(:url) }
        it { should_not include(:foo) }
      end
      context 'with empty arrays' do
        before do
          allow(current)
            .to receive(:raw_data)
            .and_return(categories: [], tags: [])
        end
        it { should_not include(:categories) }
        it { should_not include(:tags) }
      end
    end

    context 'with real data' do
      context 'with a page' do
        let(:file) { site.__find_file('about.md') }
        it { should include(author: 'Myself') }
        it { should_not include(:collection) }
        it { should_not include(:date) }
        it { should include(slug: 'about') }
        it { should_not include(:tags) }
        it { should include(type: 'page') }
        it { should include(title: 'About') }
        it { should include(url: '/about.html') }
        it { should include(custom1: 'foo') }
        it { should include(custom2: 'bar') }
      end
      context 'with a post' do
        let(:file) { site.__find_file('-test-post.md') }
        it { should_not include(:collection) }
        it { should include(categories: %w[foo bar]) }
        it { should include(date: 1_435_788_000) }
        it { should include(ext: '.md') }
        it { should include(slug: 'test-post') }
        it { should include(tags: ['tag', 'another tag']) }
        it { should include(type: 'post') }
        it { should include(title: 'Test post') }
        it { should include(url: '/foo/bar/2015/07/02/test-post.html') }
      end
      context 'with a collection document' do
        let(:file) { site.__find_file('collection-item.html') }
        it { should include(collection: 'my-collection') }
        it { should include(date: 452_469_600) }
        it { should include(slug: 'collection-item') }
        it { should_not include(:tags) }
        it { should include(type: 'document') }
        it { should include(title: 'Collection Item') }
        it { should include(url: '/my-collection/collection-item.html') }
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
