require 'spec_helper'

describe(Jekyll::Algolia::Extractor) do
  let(:current) { Jekyll::Algolia::Extractor }
  describe '.extract_raw_records' do
    let(:content) { 'some html markup' }
    let(:html_extractor) { double('AlgoliaHTMLExtractor', extract: nil) }
    let(:configurator) { Jekyll::Algolia::Configurator }
    before do
      allow(AlgoliaHTMLExtractor).to receive(:new).and_return(html_extractor)
    end
    before do
      allow(configurator).to receive(:algolia).with('nodes_to_index').and_return('foo')
    end

    before { current.extract_raw_records(content) }

    it { expect(AlgoliaHTMLExtractor).to have_received(:new).with(content, anything) }
    it do
      expect(configurator).to have_received(:algolia).with('nodes_to_index')
      expected_options = { options: { css_selector: 'foo' } }
      expect(AlgoliaHTMLExtractor).to have_received(:new).with(anything, expected_options)
    end
    it { expect(html_extractor).to have_received(:extract) }
  end
end
