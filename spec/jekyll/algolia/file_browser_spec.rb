# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable Metrics/BlockLength
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
    subject { current.absolute_path(filepath) }

    let(:source) { '/path/to/jekyll/' }

    before do
      allow(configurator).to receive(:get)
      allow(configurator).to receive(:get).with('source').and_return(source)
    end

    context 'with an absolute path and absolute source' do
      let(:filepath) { '/absolute/path/to/file.ext' }
      it { should eq filepath }
    end
    context 'with an relative path and absolute source' do
      let(:filepath) { 'file.ext' }
      let(:source) { '/path/to/jekyll/source/' }
      it { should eq '/path/to/jekyll/source/file.ext' }
    end
    context 'with a absolute path and relative source' do
      let(:filepath) { "#{Dir.pwd}/file.ext" }
      let(:source) { '.' }
      it { should eq filepath }
    end
    context 'with a relative path and relative source' do
      let(:filepath) { 'file.ext' }
      let(:source) { '.' }
      it { should eq "#{Dir.pwd}/file.ext" }
    end
  end

  describe '.relative_path' do
    subject { current.relative_path(filepath) }

    before do
      allow(configurator).to receive(:get).with('source').and_return(source)
    end

    context 'with an absolute path and absolute source' do
      let(:filepath) { '/path/to/jekyll/file.ext' }
      let(:source) { '/path/to/jekyll/' }
      it { should eq 'file.ext' }
    end
    context 'with a relative path and absolute source' do
      let(:filepath) { 'file.ext' }
      let(:source) { '/path/to/jekyll/' }
      it { should eq filepath }
    end
    context 'with and absolute path and relative source' do
      let(:filepath) { "#{Dir.pwd}/file.ext" }
      let(:source) { '.' }
      it { should eq 'file.ext' }
    end
    context 'with and relative path and relative source' do
      let(:filepath) { 'file.ext' }
      let(:source) { '.' }
      it { should eq 'file.ext' }
    end
    context 'with a relative path starting with ./' do
      let(:filepath) { './file.ext' }
      let(:source) { '.' }
      it { should eq 'file.ext' }
    end
    context 'with a relative path starting with ./' do
      let(:filepath) { './file.ext' }
      let(:source) { '/path/to/jekyll' }
      it { should eq 'file.ext' }
    end
  end

  describe '.indexable?' do
    let(:file) { double('File') }
    let(:static_file) { false }
    let(:is_404) { false }
    let(:redirect) { false }
    let(:allowed_extension) { true }
    let(:excluded_from_config) { false }
    let(:excluded_from_hook) { false }

    subject { current.indexable?(file) }

    before do
      allow(current).to receive(:static_file?).and_return(static_file)
      allow(current).to receive(:is_404?).and_return(is_404)
      allow(current).to receive(:redirect?).and_return(redirect)
      allow(current)
        .to receive(:allowed_extension?)
        .and_return(allowed_extension)
      allow(current)
        .to receive(:excluded_from_config?)
        .and_return(excluded_from_config)
      allow(current)
        .to receive(:excluded_from_hook?)
        .and_return(excluded_from_hook)
    end

    context 'with a static asset' do
      let(:static_file) { true }
      it { should eq false }
    end
    context 'with a 404 page' do
      let(:is_404) { true }
      it { should eq false }
    end
    context 'with a redirect page' do
      let(:redirect) { true }
      it { should eq false }
    end
    context 'with a disallowed extension' do
      let(:allowed_extension) { false }
      it { should eq false }
    end
    context 'excluded from config' do
      let(:excluded_from_config) { true }
      it { should eq false }
    end
    context 'excluded from hooks' do
      let(:excluded_from_hook) { true }
      it { should eq false }
    end
  end

  describe '.static_file?' do
    let(:file) { double('File') }

    subject { current.static_file?(file) }

    before do
      allow(file)
        .to receive(:is_a?)
        .with(Jekyll::StaticFile)
        .and_return(is_static)
    end

    context 'with a static file' do
      let(:is_static) { true }
      it { should eq true }
    end
    context 'with an non static file' do
      let(:is_static) { false }
      it { should eq false }
    end
  end

  describe '.is_404?' do
    let(:file) { double('File', path: path) }

    subject { current.is_404?(file) }

    describe '404.md' do
      let(:path) { './path/to/404.md' }
      it { should eq true }
    end
    describe '404.html' do
      let(:path) { './path/to/404.html' }
      it { should eq true }
    end
    describe 'anything else' do
      let(:path) { './path/to/foobar.md' }
      it { should eq false }
    end
  end

  describe '.redirect?' do
    subject { current.redirect?(file) }

    describe 'file with no name' do
      let(:file) { double('File') }
      it { should eq false }
    end

    describe 'file with a name, but not a redirect' do
      let(:file) { double('File', name: 'foo.html') }
      it { should eq false }
    end

    describe 'redirect file' do
      let(:file) { double('File', name: 'redirect.html') }
      it { should eq true }
    end
  end

  describe '.allowed_extension?' do
    let(:file) { double('File', path: path) }

    subject { current.allowed_extension?(file) }

    before do
      allow(configurator)
        .to receive(:algolia)
        .with('extensions_to_index')
        .and_return(extensions)
    end

    describe do
      let(:extensions) { %w[html md] }

      context 'html file' do
        let(:path) { 'file.html' }
        it { should eq true }
      end

      context 'md file' do
        let(:path) { 'file.md' }
        it { should eq true }
      end

      context 'dhtml file' do
        let(:path) { 'file.dhtml' }
        it { should eq false }
      end
    end
  end

  describe '.excluded_from_config?' do
    let(:file) { double('Jekyll::File', path: filepath) }

    subject { current.excluded_from_config?(file) }

    before do
      allow(configurator).to receive(:algolia).and_call_original
      allow(configurator)
        .to receive(:algolia)
        .with('files_to_exclude')
        .and_return(files_to_exclude)
      allow(configurator).to receive(:get).and_call_original
      allow(configurator)
        .to receive(:get)
        .with('source')
        .and_return('./spec/site')
    end

    context 'file in root' do
      describe do
        let(:files_to_exclude) { ['excluded.html'] }
        let(:filepath) { 'excluded.html' }
        it { should eq true }
      end
      describe do
        let(:files_to_exclude) { ['excluded.html'] }
        let(:filepath) { './excluded.html' }
        it { should eq true }
      end
      describe do
        let(:files_to_exclude) { ['./excluded.html'] }
        let(:filepath) { './excluded.html' }
        it { should eq true }
      end
      describe do
        let(:files_to_exclude) { ['./excluded.html'] }
        let(:filepath) { 'excluded.html' }
        it { should eq true }
      end
    end

    context 'in a subdir' do
      describe do
        let(:files_to_exclude) { ['excluded_dir/file.html'] }
        let(:filepath) { 'excluded_dir/file.html' }
        it { should eq true }
      end
      describe do
        let(:files_to_exclude) { ['excluded_dir/file.html'] }
        let(:filepath) { './excluded_dir/file.html' }
        it { should eq true }
      end
      describe do
        let(:files_to_exclude) { ['./excluded_dir/file.html'] }
        let(:filepath) { './excluded_dir/file.html' }
        it { should eq true }
      end
      describe do
        let(:files_to_exclude) { ['./excluded_dir/file.html'] }
        let(:filepath) { 'excluded_dir/file.html' }
        it { should eq true }
      end
    end

    context 'whole subdir' do
      describe do
        let(:files_to_exclude) { ['excluded_dir/*'] }
        let(:filepath) { 'excluded_dir/file.html' }
        it { should eq true }
      end
      describe do
        let(:files_to_exclude) { ['excluded_dir/*'] }
        let(:filepath) { './excluded_dir/file.html' }
        it { should eq true }
      end
      describe do
        let(:files_to_exclude) { ['./excluded_dir/*'] }
        let(:filepath) { './excluded_dir/file.html' }
        it { should eq true }
      end
      describe do
        let(:files_to_exclude) { ['./excluded_dir/*'] }
        let(:filepath) { 'excluded_dir/file.html' }
        it { should eq true }
      end
    end

    context 'file following a pattern' do
      context '* pattern' do
        describe do
          let(:files_to_exclude) { ['*.html'] }
          let(:filepath) { 'excluded.html' }
          it { should eq true }
        end
        describe do
          let(:files_to_exclude) { ['*.html'] }
          let(:filepath) { './excluded.html' }
          it { should eq true }
        end
        describe do
          let(:files_to_exclude) { ['./*.html'] }
          let(:filepath) { 'excluded.html' }
          it { should eq true }
        end
        describe do
          let(:files_to_exclude) { ['./*.html'] }
          let(:filepath) { './excluded.html' }
          it { should eq true }
        end
        describe '* patterns do not go into subdir' do
          let(:files_to_exclude) { ['*.html'] }
          let(:filepath) { 'excluded_dir/file.html' }
          it { should eq false }
        end
      end
      context '*/* patterns' do
        describe do
          let(:files_to_exclude) { ['*/*.html'] }
          let(:filepath) { 'excluded_dir/file.html' }
          it { should eq true }
        end
        describe do
          let(:files_to_exclude) { ['./*/*.html'] }
          let(:filepath) { 'excluded_dir/file.html' }
          it { should eq true }
        end
        describe 'do not go too deep' do
          let(:files_to_exclude) { ['*/*.html'] }
          let(:filepath) { 'foo/bar/baz.html' }
          it { should eq false }
        end
      end
      context '**/* pattern' do
        describe do
          let(:files_to_exclude) { ['**/*.html'] }
          let(:filepath) { 'file.html' }
          it { should eq true }
        end
        describe do
          let(:files_to_exclude) { ['**/*.html'] }
          let(:filepath) { 'foo/file.html' }
          it { should eq true }
        end
        describe do
          let(:files_to_exclude) { ['**/*.html'] }
          let(:filepath) { 'foo/bar/baz.html' }
          it { should eq true }
        end
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

  describe '.tags' do
    subject { current.tags(file) }

    context 'with a page with tags' do
      let(:file) { site.__find_file('page-with-tags.md') }
      it { should eq %w[tag1 tag2] }
    end
    context 'with a page without tags' do
      let(:file) { site.__find_file('about.md') }
      it { should eq [] }
    end
    context 'with a post with tags' do
      let(:file) { site.__find_file('-post-with-tags.md') }
      it { should eq %w[tag1 tag2] }
    end
    context 'with a post without tags' do
      let(:file) { site.__find_file('-post-without-tags.md') }
      it { should eq [] }
    end
    context 'with a collection element with tags' do
      let(:file) do
        site.__find_file('_my-collection/collection-item-with-tags.html')
      end
      it { should eq %w[tag1 tag2] }
    end
    context 'with a collection element without tags' do
      let(:file) { site.__find_file('_my-collection/collection-item.html') }
      it { should eq [] }
    end
  end

  describe '.categories' do
    subject { current.categories(file) }

    context 'with a page with categories' do
      let(:file) { site.__find_file('page-with-categories.md') }
      it { should eq %w[category1 category2] }
    end
    context 'with a page without categories' do
      let(:file) { site.__find_file('about.md') }
      it { should eq [] }
    end
    context 'with a post with categories' do
      let(:file) { site.__find_file('-post-with-categories.md') }
      it { should eq %w[category1 category2] }
    end
    context 'with a post without categories' do
      let(:file) { site.__find_file('-post-without-categories.md') }
      it { should eq [] }
    end
    context 'with a collection element with categories' do
      let(:file) do
        site.__find_file('_my-collection/collection-item-with-categories.html')
      end
      it { should eq %w[category1 category2] }
    end
    context 'with a collection element without tags' do
      let(:file) { site.__find_file('_my-collection/collection-item.html') }
      it { should eq [] }
    end
  end

  describe '.date' do
    subject { current.date(site.__find_file(filepath)) }

    context 'page' do
      describe 'nothing in front matter' do
        let(:filepath) { 'about.md' }
        it { should eq nil }
      end
      describe 'date in front matter' do
        let(:filepath) { 'front_matter.md' }
        it { should eq 1_521_500_400 }
      end
    end

    context 'post' do
      describe 'only date in filepath' do
        let(:filepath) { 'post-with-date.md' }
        it { should eq 1_521_414_000 }
      end
      describe 'date set in frontmatter' do
        let(:filepath) { 'test-post.md' }
        it { should eq 1_435_788_000 }
      end
      describe 'with a custom timezone' do
        let(:site) { init_new_jekyll_site(timezone: 'America/New_York') }
        let(:filepath) { 'test-post.md' }
        it { should eq 1_435_809_600 }
      end
    end

    context 'collection' do
      describe 'no date defined' do
        let(:filepath) { 'sample-item.md' }
        it { should eq nil }
      end
      describe 'date in frontmatter' do
        let(:filepath) { 'collection-item.md' }
        it { should eq 452_469_600 }
      end
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

  describe '.use_default_excerpt?' do
    subject { current.use_default_excerpt?(site.__find_file(filepath)) }

    describe 'with a page' do
      let(:filepath) { 'default-excerpt.md' }
      it { should eq false }
    end

    describe 'with a collection item' do
      let(:filepath) { 'sample-item.md' }
      it { should eq false }
    end

    context 'with a post' do
      describe 'no custom separator set' do
        let(:filepath) { 'post-with-default-excerpt.md' }
        it { should eq false }
      end
      describe 'custom separator set' do
        let(:site) do
          init_new_jekyll_site(
            excerpt_separator: '<!-- excerpt_separator -->'
          )
        end
        let(:filepath) { 'post-with-default-excerpt.md' }

        it { should eq false }
      end
      describe 'custom separator set and present in the file' do
        let(:site) do
          init_new_jekyll_site(
            excerpt_separator: '<!-- excerpt_separator -->'
          )
        end
        let(:filepath) { 'post-with-custom-excerpt.md' }

        it { should eq true }
      end
    end
  end

  describe '.excerpt_html' do
    subject { current.excerpt_html(site.__find_file(filepath)) }

    describe 'should use the default excerpt if needed' do
      let(:filepath) { 'default-excerpt.md' }
      before do
        allow(current)
          .to receive(:use_default_excerpt?)
          .and_return(true)
        allow(current)
          .to receive(:excerpt_raw)
          .and_return('custom excerpt')
      end
      it { should eq 'custom excerpt' }
    end

    context 'with a page' do
      describe 'default settings' do
        let(:filepath) { 'default-excerpt.md' }
        let(:expected) { '<p>foo</p>' }
        it { should eq expected }
      end

      describe 'custom nodes_to_index' do
        let(:filepath) { 'default-excerpt.md' }
        let(:expected) { '<div>baz</div>' }
        before do
          allow(configurator)
            .to receive(:algolia)
            .and_call_original
          allow(configurator)
            .to receive(:algolia)
            .with('nodes_to_index')
            .and_return('div')
        end
        it { should eq expected }
      end
    end

    context 'with a post' do
      describe 'default settings' do
        let(:filepath) { 'post-with-default-excerpt.md' }
        let(:expected) { '<p>foo</p>' }
        it { should eq expected }
      end

      describe 'custom nodes_to_index' do
        let(:filepath) { 'post-with-default-excerpt.md' }
        let(:expected) { '<div>baz</div>' }
        before do
          allow(configurator)
            .to receive(:algolia)
            .and_call_original
          allow(configurator)
            .to receive(:algolia)
            .with('nodes_to_index')
            .and_return('div')
        end
        it { should eq expected }
      end
    end
  end

  describe '.excerpt_text' do
    subject { current.excerpt_text(site.__find_file(filepath)) }

    context 'with a page' do
      describe 'default settings' do
        let(:filepath) { 'default-excerpt.md' }
        let(:expected) { 'foo' }
        it { should eq expected }
      end

      describe 'custom nodes_to_index' do
        let(:filepath) { 'default-excerpt.md' }
        let(:expected) { 'baz' }
        before do
          allow(configurator)
            .to receive(:algolia)
            .and_call_original
          allow(configurator)
            .to receive(:algolia)
            .with('nodes_to_index')
            .and_return('div')
        end
        it { should eq expected }
      end
    end

    context 'with a post' do
      describe 'default settings' do
        let(:filepath) { 'post-with-default-excerpt.md' }
        let(:expected) { 'foo' }
        it { should eq expected }
      end

      describe 'custom nodes_to_index' do
        let(:filepath) { 'post-with-default-excerpt.md' }
        let(:expected) { 'baz' }
        before do
          allow(configurator)
            .to receive(:algolia)
            .and_call_original
          allow(configurator)
            .to receive(:algolia)
            .with('nodes_to_index')
            .and_return('div')
        end
        it { should eq expected }
      end

      describe 'custom excerpt_separator defined in config' do
        let(:site) do
          init_new_jekyll_site(
            excerpt_separator: '<!-- excerpt_separator -->'
          )
        end
        let(:filepath) { 'post-with-custom-excerpt.md' }
        let(:expected) { 'foo bar' }

        it { should eq expected }
      end
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
        should_not include(:categories)
        should_not include(:tags)
      end
    end
    context 'with a collection item' do
      let(:file) { site.__find_file('collection-item.html') }
      it do
        should include(title: 'Collection Item')
        should_not include(:categories)
        should_not include(:tags)
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
    describe 'should not contain keys added by Jekyll unused in search' do
      describe do
        let(:file) { site.__find_file('about.md') }
        it do
          should_not include(:draft)
          should_not include(:ext)
        end
      end
      describe do
        let(:file) { site.__find_file('-test-post.md') }
        it do
          should_not include(:draft)
          should_not include(:ext)
        end
      end
      describe do
        let(:file) { site.__find_file('collection-item.html') }
        it do
          should_not include(:draft)
          should_not include(:ext)
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
        allow(current).to receive(:tags).and_return('tags')
        allow(current).to receive(:categories).and_return('categories')
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
        it { should include(categories: 'categories') }
        it { should include(tags: 'tags') }
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
    end

    context 'with real data' do
      context 'with a page' do
        let(:file) { site.__find_file('about.md') }
        it { should include(author: 'Myself') }
        it { should include(tags: []) }
        it { should include(categories: []) }
        it { should_not include(:collection) }
        it { should_not include(:date) }
        it { should include(slug: 'about') }
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
        it { should include(tags: []) }
        it { should include(categories: []) }
        it { should include(type: 'document') }
        it { should include(title: 'Collection Item') }
        it { should include(url: '/my-collection/collection-item.html') }
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
