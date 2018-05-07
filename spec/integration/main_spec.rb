# frozen_string_literal: true

require_relative './spec_helper'

# rubocop:disable Metrics/BlockLength
describe('pushed index') do
  before(:all) do
    @index = Algolia::Index.new(ENV['ALGOLIA_INDEX_NAME'])
  end

  describe('built website') do
    # Files excluded from indexing should still be written on disk
    it { should have_file('404.html') }
    it { should have_file('index.html') }
  end

  # Custom hooks are executed, even if github-pages is added as a gem
  describe 'hooks' do
    describe 'exclude a file through should_be_excluded?' do
      subject { @index.search('iamexcludedthroughhooks')['hits'].length }
      it { should eq 0 }
    end
    describe 'update all records through before_indexing_each' do
      subject { @index.search('')['hits'][0]['added_through_each'] }
      it { should eq true }
    end
    describe 'add a new record through before_indexing_all' do
      subject { @index.search('iamaddedthroughhooks')['hits'].length }
      it { should eq 1 }
    end
  end

  # https://github.com/algolia/jekyll-algolia/issues/49
  describe 'attributesToSnippet' do
    subject { @index.get_settings['attributesToSnippet'] }
    it { should eq ['content:10'] }
  end

  # https://github.com/algolia/jekyll-algolia/issues/45
  describe 'UTF-8 search' do
    subject { @index.search(keyword)['hits'][0]['title'] }
    context '∀' do
      let(:keyword) { '∀' }
      it { should eq 'Math symbols' }
    end
    context 'λ' do
      let(:keyword) { 'λ' }
      it { should eq 'Math symbols' }
    end
    context '→' do
      let(:keyword) { '→' }
      it { should eq 'Math symbols' }
    end
  end

  describe 'nbHits' do
    subject { @index.search('', distinct: distinct)['nbHits'] }

    context 'by default' do
      let(:distinct) { nil }
      it { should eq 5 }
    end
    context 'with distinct:true' do
      let(:distinct) { true }
      it { should eq 5 }
    end
    context 'with distinct:false' do
      let(:distinct) { false }
      it { should eq 9 }
    end
  end
end
# rubocop:enable Metrics/BlockLength
