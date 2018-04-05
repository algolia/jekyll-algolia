# frozen_string_literal: true

require 'spec_helper'

describe 'overwrites' do
  let(:site) { init_new_jekyll_site }
  before do
    allow(Jekyll.logger).to receive(:info)
    allow(Jekyll.logger).to receive(:warn)
  end

  describe(Jekyll::Document) do
    let(:current) { site.__find_file('collection-item.md') }

    subject { current.date }

    before do
      allow(current).to receive(:data).and_return(data)
    end

    describe 'return the date if we have it' do
      let(:data) { { 'date' => 'my_date' } }
      it { should eq 'my_date' }
    end

    describe 'return nil if no date defined' do
      let(:data) { {} }
      it { should eq nil }
    end
  end

  describe(JekyllAlgoliaLink) do
    let(:current) { site.__find_file('links.md') }

    subject { current.content }

    describe 'should link to a page' do
      it { should include('page: /about.html') }
    end

    describe 'should link to a page in a subdir' do
      it { should include('page in subdir: /subdir/subpage.html') }
    end

    describe 'should link to file excluded from indexing' do
      it { should include('excluded page: /excluded.html') }
    end

    describe 'should link to an asset' do
      it { should include('asset: /assets/ring.png') }
    end

    describe 'should link to a blog post' do
      it { should include('blog post: /foo/bar/2015/07/02/test-post.html') }
    end

    describe 'should link to collection item' do
      it do
        should include('collection item: /my-collection/collection-item.html')
      end
    end
  end
end
