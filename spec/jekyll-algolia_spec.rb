# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
require 'spec_helper'

describe(Jekyll::Algolia) do
  let(:configurator) { Jekyll::Algolia::Configurator }
  let(:current) { Jekyll::Algolia }
  let(:extractor) { Jekyll::Algolia::Extractor }
  let(:logger) { Jekyll::Algolia::Logger }
  let(:file_browser) { Jekyll::Algolia::FileBrowser }
  let(:hooks) { Jekyll::Algolia::Hooks }
  let(:indexer) { Jekyll::Algolia::Indexer }

  # Suppress Jekyll log about not having a config file
  before do
    allow(Jekyll.logger).to receive(:warn)
    allow(logger).to receive(:log)
  end

  describe '.init' do
    let(:config) { Jekyll.configuration }

    context 'with valid Algolia credentials' do
      subject { current.init(config) }

      before do
        allow(configurator)
          .to receive(:assert_valid_credentials)
          .and_return(true)
      end

      it 'should make the site accessible from the outside' do
        expect(subject.site.config).to include(config)
      end
      it 'should check for deprecation warnings' do
        expect(configurator).to receive(:warn_of_deprecated_options)

        current.init(config)
      end
    end

    context 'with invalid Algolia credentials' do
      subject { -> { current.init(config) } }
      before do
        allow(configurator)
          .to receive(:assert_valid_credentials)
          .and_return(false)
      end

      it { is_expected.to raise_error SystemExit }
    end
  end

  describe 'overriding Jekyll::Site#process' do
    let(:configuration) { Jekyll.configuration }
    let(:jekyll_site) { Jekyll::Site.new(configuration) }
    let(:algolia_site) { Jekyll::Algolia::Site.new(configuration) }
    let!(:initial_method) { jekyll_site.method(:process).source_location }
    let!(:overridden_method) { algolia_site.method(:process).source_location }

    before do
      allow(algolia_site).to receive(:reset)
      allow(algolia_site).to receive(:read)
      allow(algolia_site).to receive(:generate)
      allow(algolia_site).to receive(:keep_only_indexable_files)
      allow(algolia_site).to receive(:render)
      allow(algolia_site).to receive(:push)
      allow(algolia_site).to receive(:cleanup)
      allow(algolia_site).to receive(:write)
    end

    it 'should change the initial .write method' do
      expect(overridden_method).to_not eq initial_method
    end

    describe 'should call the preflight generation' do
      before do
        algolia_site.process
      end

      it do
        expect(algolia_site).to have_received(:reset)
        expect(algolia_site).to have_received(:read)
        expect(algolia_site).to have_received(:generate)
      end
    end

    describe 'should clean the list of files' do
      before do
        algolia_site.process
      end

      it do
        expect(algolia_site).to have_received(:keep_only_indexable_files)
      end
    end

    describe 'should convert markdown to html' do
      before do
        algolia_site.process
      end

      it do
        expect(algolia_site).to have_received(:render)
      end
    end

    describe 'should push records' do
      before do
        algolia_site.process
      end

      it do
        expect(algolia_site).to have_received(:push)
      end
    end

    describe 'should not call the original cleanup' do
      before do
        algolia_site.process
      end

      it do
        expect(algolia_site).to_not have_received(:cleanup)
      end
    end

    describe 'should not call the original write' do
      before do
        algolia_site.process
      end

      it do
        expect(algolia_site).to_not have_received(:write)
      end
    end
  end

  describe 'Jekyll::Site#indexable_list' do
    let(:algolia_site) { Jekyll::Algolia::Site.new(Jekyll.configuration) }

    subject { algolia_site.indexable_list(items) }

    describe 'remove non-indexable elements' do
      let(:item1) { double('Item', name: 'foo', data: {}) }
      let(:item2) { double('Item', name: 'bar', data: {}) }
      let(:items) { [item1, item2] }

      before do
        allow(file_browser).to receive(:indexable?).and_return(true)
        allow(file_browser)
          .to receive(:indexable?)
          .with(item2)
          .and_return(false)
      end

      it do
        expect(subject.length).to eq 1
        expect(subject[0]).to eq item1
      end
    end

    describe 'set layout to nil' do
      let(:items) do
        [
          double('Item', name: 'foo', data: {}),
          double('Item', name: 'bar', data: { 'layout' => 'post' })
        ]
      end

      before do
        allow(file_browser).to receive(:indexable?).and_return(true)
      end

      it do
        expect(subject[0].data).to include('layout' => nil)
        expect(subject[1].data).to include('layout' => nil)
      end
    end
  end

  describe 'Jekyll::Site#keep_only_indexable_files' do
    let(:site) { Jekyll::Algolia::Site.new(Jekyll.configuration) }
    let(:pages) { 'pages' }
    let(:collections) { { foo: collection } }
    let(:collection) { double('Collection', docs: 'collection') }
    let(:static_files) { 'static_pages' }

    before do
      allow(site)
        .to receive(:indexable_list)
      allow(collection).to receive(:docs=)
      site.pages = pages
      site.collections = collections
      site.static_files = static_files
    end

    describe 'should clean the pages' do
      before do
        expect(site)
          .to receive(:indexable_list)
          .with(pages)
          .and_return('after_pages')
        site.keep_only_indexable_files
      end

      it do
        expect(site.pages).to eq 'after_pages'
      end
    end

    describe 'should clean the documents' do
      before do
        allow(site)
          .to receive(:indexable_list)
          .with('collection')
          .and_return('after_collection')
        allow(collection)
          .to receive(:docs=)
          .with('after_collection')
        site.keep_only_indexable_files
      end

      it do
        expect(site).to have_received(:indexable_list).with('collection')
        expect(collection).to have_received(:docs=).with('after_collection')
      end
    end

    describe 'should clean the static files' do
      before do
        site.keep_only_indexable_files
      end

      it do
        expect(site.static_files).to eq []
      end
    end
  end

  describe 'Jekyll::Site#push' do
    let(:file_foo) { double('File', path: 'foo') }
    let(:file_bar) { double('File', path: 'bar') }
    let(:records_foo) { [{ name: 'foo1' }, { name: 'foo2' }] }
    let(:records_bar) { [{ name: 'bar1' }, { name: 'bar2' }] }
    let(:site) { Jekyll::Algolia::Site.new(Jekyll.configuration) }

    before do
      allow(site)
        .to receive(:each_site_file)
        .and_yield(file_foo)
        .and_yield(file_bar)
      allow(extractor).to receive(:run)
      allow(extractor).to receive(:run).with(file_foo).and_return(records_foo)
      allow(extractor).to receive(:run).with(file_bar).and_return(records_bar)
      allow(extractor).to receive(:add_unique_object_id) { |arg| arg }
      allow(file_browser).to receive(:indexable?).and_return(true)
      allow(file_browser).to receive(:relative_path)
      allow(hooks).to receive(:apply_all) { |arg| arg }
      allow(logger).to receive(:verbose)
      allow(indexer).to receive(:run)
    end

    describe 'push records' do
      before do
        site.push
      end

      it do
        expect(indexer)
          .to have_received(:run)
          .with([
                  { name: 'foo1' },
                  { name: 'foo2' },
                  { name: 'bar1' },
                  { name: 'bar2' }
                ])
      end
    end

    describe 'exclude non-indexable elements' do
      before do
        expect(file_browser)
          .to receive(:indexable?)
          .with(file_bar)
          .and_return(false)

        site.push
      end

      it do
        expect(indexer)
          .to have_received(:run)
          .with(records_foo)
      end
    end

    describe 'displaying number of files processed' do
      before do
        site.push
      end

      it do
        expect(logger).to have_received(:verbose).with(/2 files/)
      end
    end

    describe 'display path of files in verbose mode' do
      before do
        allow(file_browser)
          .to receive(:relative_path)
          .with('foo')
          .and_return('foo-path')
        allow(file_browser)
          .to receive(:relative_path)
          .with('bar')
          .and_return('bar-path')

        site.push
      end

      it do
        expect(logger).to have_received(:verbose).with(/foo-path/)
        expect(logger).to have_received(:verbose).with(/bar-path/)
      end
    end

    describe 'call hooks on all records' do
      before do
        site.push
      end

      it do
        expect(hooks)
          .to have_received(:apply_all)
          .with([
                  { name: 'foo1' },
                  { name: 'foo2' },
                  { name: 'bar1' },
                  { name: 'bar2' }
                ])
      end
    end

    describe 'add a unique id to each record' do
      before do
        site.push
      end

      it do
        expect(extractor)
          .to have_received(:add_unique_object_id)
          .with(name: 'foo1')
        expect(extractor)
          .to have_received(:add_unique_object_id)
          .with(name: 'foo2')
        expect(extractor)
          .to have_received(:add_unique_object_id)
          .with(name: 'bar1')
        expect(extractor)
          .to have_received(:add_unique_object_id)
          .with(name: 'bar2')
      end
    end
  end

  describe '.run' do
    # Prevent the whole process to stop if Algolia config is not available
    before do
      allow(configurator)
        .to receive(:assert_valid_credentials)
        .and_return(true)
    end

    let(:configuration) { Jekyll.configuration }
    let(:algolia_site) { double('Jekyll::Algolia::Site', process: nil) }
    before do
      # Making sure all methods are called on the relevant objects
      expect(Jekyll::Algolia::Site)
        .to receive(:new)
        .with(configuration)
        .and_return(algolia_site)
      expect(algolia_site)
        .to receive(:process)
    end

    it { current.init(configuration).run }
  end
end
# rubocop:enable Metrics/BlockLength
