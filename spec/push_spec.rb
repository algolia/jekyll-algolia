require 'spec_helper'

describe(AlgoliaSearchJekyllPush) do
  let(:push) { AlgoliaSearchJekyllPush }
  let(:site) { get_site }
  let(:page_file) { site.file_by_name('about.md') }
  let(:html_page_file) { site.file_by_name('authors.html') }
  let(:excluded_page_file) { site.file_by_name('excluded.html') }
  let(:post_file) { site.file_by_name('2015-07-02-test-post.md') }
  let(:static_file) { site.file_by_name('ring.png') }
  let(:document_file) { site.file_by_name('collection-item.md') }
  let(:html_document_file) { site.file_by_name('collection-item.html') }
  let(:items) do
    [{
      name: 'foo',
      url: '/foo'
    }, {
      name: 'bar',
      url: '/bar'
    }]
  end
  let(:options) do
    {
      'drafts' => true
    }
  end
  let(:config) do
    {
      'source' => File.expand_path('./spec/fixtures'),
      'markdown_ext' => 'md,mkd',
      'algolia' => {
        'application_id' => 'APPID',
        'index_name' => 'INDEXNAME'
      }
    }
  end

  describe 'init_options' do
    it 'sets options and config' do
      # Given
      args = nil

      # When
      push.init_options(args, options, config)

      # Then
      expect(push.options).to include(options)
      expect(push.config).to include(config)
    end

    it 'sets indexname from the commandline' do
      # Given
      args = ['newindex']

      # When
      push.init_options(args, options, config)

      # Then
      expect(push.config['algolia']['index_name']).to eq 'newindex'
    end
  end

  describe 'indexable?' do
    before(:each) do
      push.init_options(nil, options, config)
    end

    it 'exclude StaticFiles' do
      expect(push.indexable?(static_file)).to eq false
    end

    it 'keeps markdown files' do
      expect(push.indexable?(page_file)).to eq true
    end

    it 'keeps html files' do
      expect(push.indexable?(html_page_file)).to eq true
    end

    it 'keeps markdown documents' do
      expect(push.indexable?(document_file)).to eq true
    end

    it 'keeps html documents' do
      expect(push.indexable?(html_document_file)).to eq true
    end

    it 'exclude file specified in config' do
      # Given
      config['algolia']['excluded_files'] = [
        'excluded.html'
      ]
      push.init_options(nil, options, config)

      # Then
      expect(push.indexable?(excluded_page_file)).to eq false
    end
  end

  describe 'configure_index' do
    it 'sets some sane defaults' do
      # Given
      push.init_options(nil, options, config)
      index = double

      # Then
      expected = {
        attributeForDistinct: 'title',
        distinct: true,
        customRanking: ['desc(posted_at)', 'desc(weight)']
      }
      expect(index).to receive(:set_settings).with(hash_including(expected))

      # When
      push.configure_index(index)
    end

    it 'allow user to override all settings' do
      # Given
      settings = {
        distinct: false,
        customSetting: 'foo',
        customRanking: ['asc(foo)', 'desc(bar)']
      }
      config['algolia']['settings'] = settings
      push.init_options(nil, options, config)
      index = double

      # Then
      expect(index).to receive(:set_settings).with(hash_including(settings))

      # When
      push.configure_index(index)
    end
  end

  describe 'jekyll_new' do
    it 'should return a patched version of site with a custom write' do
      # Given
      normal_site = Jekyll::Site.new(Jekyll.configuration(config))
      normal_method = normal_site.method(:write).source_location

      patched_site = get_site({}, mock_write_method: false, process: false)
      patched_method = patched_site.method(:write).source_location

      # When
      # Then
      expect(patched_method).not_to eq normal_method
    end
  end

  describe 'process' do
    it 'should call the site write method' do
      # Given
      site = get_site({}, process: false)

      # When
      site.process

      # Then
      expect(site).to have_received(:write)
    end

    it 'should push items to Algolia' do
      # Given
      site = get_site({}, mock_write_method: false, process: false)
      # Keep only page_file
      allow(AlgoliaSearchJekyllPush).to receive(:indexable?) do |file|
        file.path == page_file.path
      end
      allow(AlgoliaSearchJekyllPush).to receive(:push)

      # When
      site.process

      # Then
      expect(AlgoliaSearchJekyllPush).to have_received(:push) do |arg|
        expect(arg.size).to eq 6
      end
    end
  end

  describe 'push' do
    let(:index_double) { double('Algolia Index').as_null_object }

    before(:each) do
      push.init_options(nil, options, config)
      # Mock all calls to not send anything
      allow_any_instance_of(AlgoliaSearchCredentialChecker)
        .to receive(:assert_valid)
      allow(Algolia).to receive(:init)
      allow(Algolia).to receive(:move_index)
      allow(Algolia::Index).to receive(:new).and_return(index_double)
      allow(Jekyll.logger).to receive(:info)
    end

    it 'should create a temporary index' do
      # Given

      # When
      push.push(items)

      # Then
      expect(Algolia::Index).to have_received(:new).with('INDEXNAME_tmp')
    end

    it 'should add elements to the temporary index' do
      # Given

      # When
      push.push(items)

      # Then
      expect(index_double).to have_received(:add_objects!)
    end

    it 'should move the temporary index as the main one' do
      # Given

      # When
      push.push(items)

      # Then
      expect(Algolia).to have_received(:move_index)
                         .with('INDEXNAME_tmp', 'INDEXNAME')
    end

    it 'should display the number of elements indexed' do
      # Given

      # When
      push.push(items)

      # Then
      expect(Jekyll.logger).to have_received(:info).with(/of 2 items/i)
    end

    it 'should display an error if `add_objects!` failed' do
      # Given
      allow(index_double).to receive(:add_objects!).and_raise

      expect(Jekyll.logger).to receive(:error)
      expect(-> { push.push(items) }).to raise_error SystemExit
    end
  end
end
