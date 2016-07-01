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
  let(:pagination_page) { site.file_by_name('page2/index.html') }
  let(:err_404) { site.file_by_name('404.md') }
  let(:err_404_html) { site.file_by_name('404.html') }
  let(:homepage) { site.file_by_name('index.html') }
  let(:items) do
    [{
      name: 'foo',
      url: '/foo'
    }, {
      name: 'bar',
      url: '/bar'
    }]
  end

  describe 'init_options' do
    it 'sets options and config' do
      # Given
      args = nil
      options = { 'foo' => 'bar' }
      config = { 'bar' => 'foo' }

      # When
      push.init_options(args, options, config)

      # Then
      expect(push.options).to include(options)
      expect(push.config).to include(config)
    end
  end

  describe 'indexable?' do
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
      ap document_file
      expect(push.indexable?(document_file)).to eq true
    end

    it 'keeps html documents' do
      expect(push.indexable?(html_document_file)).to eq true
    end

    it 'exclude file specified in config' do
      expect(push.indexable?(excluded_page_file)).to eq false
    end

    it 'does not index pagination pages' do
      expect(push.indexable?(pagination_page)).to eq false
    end

    it 'does not index 404 pages (in markdown)' do
      expect(push.indexable?(err_404)).to eq false
    end

    it 'does not index 404 pages (in html)' do
      expect(push.indexable?(err_404_html)).to eq false
    end

    it 'does not index homepage' do
      expect(push.indexable?(homepage)).to eq false
    end
  end

  describe 'excluded_files?' do
    before(:each) do
      push.init_options(nil, {}, site.config)
    end

    it 'should not exclude normal pages' do
      expect(push.excluded_file?(html_page_file)).to eq false
    end

    it 'should alway exclude pagination pages' do
      expect(push.excluded_file?(pagination_page)).to eq true
    end

    it 'should exclude user specified strings' do
      expect(push.excluded_file?(excluded_page_file)).to eq true
    end
  end

  describe 'custom_hook_excluded_file?' do
    it 'let the user call a custom hook to exclude some files' do
      # Given
      def push.custom_hook_excluded_file?(_file)
        true
      end

      # Then
      expect(push.excluded_file?(html_page_file)).to eq true
    end
  end

  describe 'configure_index' do
    it 'sets some sane defaults' do
      # Given
      push.init_options(nil, {}, {})
      index = double

      # Then
      expected = {
        attributeForDistinct: 'url',
        distinct: true,
        customRanking: [
          'desc(posted_at)',
          'desc(weight.tag_name)',
          'asc(weight.position)'
        ]
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
      config = {
        'algolia' => {
          'settings' => settings
        }
      }
      push.init_options(nil, {}, config)
      index = double

      # Then
      expect(index).to receive(:set_settings).with(hash_including(settings))

      # When
      push.configure_index(index)
    end

    describe 'throw an error' do
      before(:each) do
        @index_double = double('Algolia Index').as_null_object
        @error_handler_double = double('Error Handler double').as_null_object
        push.init_options(nil, {}, {})
        allow(@index_double).to receive(:set_settings).and_raise
        allow(Jekyll.logger).to receive(:error)
      end

      it 'stops if API throw an error' do
        # Given

        # When

        # Then
        expect(-> { push.configure_index(@index_double) })
          .to raise_error SystemExit
      end

      it 'displays the error directly if unknown' do
        # Given
        allow(@error_handler_double)
          .to receive(:readable_algolia_error).and_return false
        allow(@error_handler_double)
          .to receive(:display)
        allow(AlgoliaSearchErrorHandler)
          .to receive(:new).and_return(@error_handler_double)

        # When

        # Then
        expect(-> { push.configure_index(@index_double) })
          .to raise_error SystemExit
        expect(@error_handler_double)
          .to have_received(:display).exactly(0).times
        expect(Jekyll.logger)
          .to have_received(:error).with('Algolia Error: HTTP Error')
      end

      it 'display a human readable version of the error if one is found' do
        # Given
        allow(@error_handler_double)
          .to receive(:readable_algolia_error).and_return 'known_errors'
        allow(@error_handler_double)
          .to receive(:display)
        allow(AlgoliaSearchErrorHandler)
          .to receive(:new).and_return(@error_handler_double)

        # When

        # Then
        expect(-> { push.configure_index(@index_double) })
          .to raise_error SystemExit
        expect(@error_handler_double)
          .to have_received(:display)
          .exactly(1).times
          .with('known_errors')
      end
    end
  end

  describe 'jekyll_new' do
    it 'should return a patched version of site with a custom write' do
      # Given
      normal_site = Jekyll::Site.new(Jekyll.configuration)
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

  describe 'set_user_agent_header' do
    before(:each) do
      allow(Algolia).to receive(:set_extra_header)
    end

    it 'should set a User-Agent with the plugin name and version' do
      # Given
      allow(AlgoliaSearchJekyllVersion).to receive(:to_s).and_return '99.42'

      # When
      push.set_user_agent_header

      # Then
      expect(Algolia).to have_received(:set_extra_header).with(
        'User-Agent',
        /Jekyll(.*)99.42/
      )
    end
  end

  describe 'push' do
    let(:index_double) { double('Algolia Index').as_null_object }
    let(:config) do
      {
        'algolia' => {
          'index_name' => 'INDEXNAME'
        }
      }
    end

    before(:each) do
      push.init_options(nil, {}, config)
      # Mock all calls to not send anything
      allow_any_instance_of(AlgoliaSearchCredentialChecker)
        .to receive(:assert_valid)
      allow(Algolia).to receive(:set_extra_header)
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
      allow(index_double).to receive(:add_objects!).and_raise

      expect(Jekyll.logger).to receive(:error)
      expect(-> { push.push(items) }).to raise_error SystemExit
    end
  end
end
