require 'spec_helper'

describe(Jekyll::Algolia::FileBrowser) do
  let(:current) { Jekyll::Algolia::FileBrowser }
  let(:site) { init_new_jekyll_site }

  # Suppress Jekyll log about reading the config file
  before do
    allow(Jekyll.logger).to receive(:info)
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
    end
    context 'when testing a file excluded from a custom hook' do
      let(:file) { site.__find_file('excluded-from-hook.html') }
      it { should eq true }
    end
  end
end
