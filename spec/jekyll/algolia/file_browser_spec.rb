# rubocop:disable Metrics/BlockLength
require 'spec_helper'

describe(Jekyll::Algolia::FileBrowser) do
  let(:current) { Jekyll::Algolia::FileBrowser }
  let(:site) { init_new_jekyll_site }

  # Suppress Jekyll log about reading the config file
  before { allow(Jekyll.logger).to receive(:info) }
  # Do not exit on wrong Algolia configuration
  before do
    allow(Jekyll::Algolia::Configurator)
      .to receive(:assert_valid_credentials)
      .and_return(true)
  end

  describe '.indexable?' do
    subject { current.indexable?(file) }

    context 'with a static asset' do
      let(:file) { site.__find_file('png.png') }
      it { should eq false }
    end
    context 'with a 404 file' do
      let(:file) { site.__find_file('404.html') }
      it { should eq false }
    end
    context 'with a pagination page' do
      let(:file) { site.__find_file('page2/index.html') }
      it { should eq false }
    end
    context 'with a file excluded by the config' do
      let(:file) { site.__find_file('excluded.html') }
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

  describe '.is_404?' do
    subject { current.is_404?(file) }

    context 'with an HTML file' do
      let(:file) { site.__find_file('404.html') }
      it { should eq true }
    end

    context 'with a markdown file' do
      let(:file) { site.__find_file('404.md') }
      it { should eq true }
    end
  end

  describe '.pagination_page?' do
    subject { current.pagination_page?(file) }

    context 'with a pagination page' do
      let(:file) { site.__find_file('page2/index.html') }
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
        allow(Jekyll::Algolia::Configurator)
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

  describe '.excluded_by_user?' do
    subject { current.excluded_by_user?(file) }

    context 'when testing a regular file' do
      let(:file) { site.__find_file('html.html') }
      it { should eq false }
    end
    context 'when testing a file excluded from config' do
      let(:file) { site.__find_file('excluded.html') }
      it { should eq true }
      context 'when using a glob' do
        context 'with a matching file' do
          let(:file) { site.__find_file('excluded_dir/file.html') }
          it { should eq true }
        end
        context 'with a non-matching file' do
          let(:file) { site.__find_file('excluded_dir/file.md') }
          it { should eq false }
        end
      end
    end
    context 'when testing a file excluded from a custom hook' do
      let(:file) { site.__find_file('excluded-from-hook.html') }
      it { should eq true }
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

    context 'with a regular page' do
      let(:file) { site.__find_file('about.md') }
      it { should eq nil }
    end
    context 'with a collection element' do
      let(:file) { site.__find_file('_my-collection/collection-item.html') }
      it { should eq 452_469_600 }
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

  describe '.excerpt_html' do
    let(:expected) do
      '<p>This is the first paragraph. It is especially long because we '\
      'want it to wrap on two lines.</p>'
    end

    subject { current.excerpt_html(file) }

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
    describe 'should not contain some specific keys' do
      let(:file) { site.__find_file('html.html') }
      it { should_not include(:excerpt) }
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

  describe '.path_from_root' do
    subject { current.path_from_root(file) }

    context 'with a page' do
      let(:file) { site.__find_file('about.md') }
      it { should eq 'about.md' }
    end
    context 'with a post' do
      let(:file) { site.__find_file('_posts/2015-07-03-test-post-again.md') }
      it { should eq '_posts/2015-07-03-test-post-again.md' }
    end
    context 'with a collection element' do
      let(:file) { site.__find_file('_my-collection/collection-item.html') }
      it { should eq '_my-collection/collection-item.html' }
    end
  end
end
