# rubocop:disable Metrics/BlockLength
require 'spec_helper'

describe(Jekyll::Algolia::Extractor) do
  let(:current) { Jekyll::Algolia::Extractor }

  describe '.extract_raw_records' do
    # Given
    let(:content) { 'some html markup' }
    let(:html_extractor) { double('AlgoliaHTMLExtractor', extract: nil) }
    let(:configurator) { Jekyll::Algolia::Configurator }
    before do
      allow(AlgoliaHTMLExtractor)
        .to receive(:new)
        .and_return(html_extractor)
    end
    before do
      allow(configurator)
        .to receive(:algolia)
        .with('nodes_to_index')
        .and_return('foo')
    end

    # When
    before { current.extract_raw_records(content) }

    # Then
    it 'should create a new AlgoliaHTMLExtractor with the content passed' do
      expect(AlgoliaHTMLExtractor)
        .to have_received(:new)
        .with(content, anything)
    end
    it 'should configure the extractor with the nodex_to_index config value' do
      expect(AlgoliaHTMLExtractor)
        .to have_received(:new)
        .with(anything, options: { css_selector: 'foo' })
    end
    it { expect(html_extractor).to have_received(:extract) }
  end
end
