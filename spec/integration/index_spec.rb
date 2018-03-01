# frozen_string_literal: true

require 'algoliasearch'

describe('pushed index') do
  before(:all) do
    Algolia.init(
      application_id: ENV['ALGOLIA_APPLICATION_ID'],
      api_key: ENV['ALGOLIA_API_KEY']
    )
  end

  let(:index) { Algolia::Index.new(ENV['ALGOLIA_INDEX_NAME']) }

  describe 'nbHits' do
    subject { index.search('', distinct: distinct)['nbHits'] }

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
  # snippeting attribute correctly set
end
