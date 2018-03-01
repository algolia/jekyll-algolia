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
      it { should eq 21 }
    end
    context 'with distinct:true' do
      let(:distinct) { true }
      it { should eq 21 }
    end
    context 'with distinct:false' do
      let(:distinct) { false }
      it { should eq 52 }
    end
  end

  describe 'attributesToSnippet' do
    # https://github.com/algolia/jekyll-algolia/issues/49
    subject { @index.get_settings['attributesToSnippet'] }
    it { should eq ['content:10'] }
  end
end
