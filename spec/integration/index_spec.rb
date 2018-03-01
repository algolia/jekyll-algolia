# frozen_string_literal: true

require 'algoliasearch'

describe('pushed index') do
  before(:all) do
    Algolia.init(
      application_id: ENV['ALGOLIA_APPLICATION_ID'],
      api_key: ENV['ALGOLIA_API_KEY']
    )
    @index = Algolia::Index.new(ENV['ALGOLIA_INDEX_NAME'])
  end

  describe 'nbHits' do
    subject { @index.search('', distinct: distinct)['nbHits'] }

    context 'by default' do
      let(:distinct) { nil }
      it { should eq 22 }
    end
    context 'with distinct:true' do
      let(:distinct) { true }
      it { should eq 22 }
    end
    context 'with distinct:false' do
      let(:distinct) { false }
      it { should eq 53 }
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
end
