# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
require 'spec_helper'

describe(Jekyll::Algolia::Extractor) do
  let(:configurator) { Jekyll::Algolia::Configurator }
  let(:filebrowser) { Jekyll::Algolia::FileBrowser }
  let(:hooks) { Jekyll::Algolia::Hooks }
  let(:current) { Jekyll::Algolia::Extractor }
  let(:site) { init_new_jekyll_site }

  # Suppress Jekyll log about reading the config file
  before { allow(Jekyll.logger).to receive(:info) }
  # Do not exit on wrong Algolia configuration
  before do
    allow(Jekyll::Algolia::Configurator)
      .to receive(:assert_valid_credentials)
      .and_return(true)
  end

  describe '.extract_raw_records' do
    context 'with mock data' do
      # Given
      let(:content) { 'some html markup' }
      before do
        allow(AlgoliaHTMLExtractor)
          .to receive(:run)
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
          .to have_received(:run)
          .with(content, anything)
      end
      it 'should configure the extractor with the nodex_to_index value' do
        expect(AlgoliaHTMLExtractor)
          .to have_received(:run)
          .with(anything, options: { css_selector: 'foo' })
      end
    end

    context 'with real data' do
      let(:site) { init_new_jekyll_site }
      subject { current.extract_raw_records(content) }

      context 'with a page' do
        let(:content) { site.__find_file('only-paragraphs.md').content }
        it { expect(subject.length).to eq 6 }
      end
      context 'with a page with divs' do
        let(:content) { site.__find_file('only-divs.md').content }
        before do
          allow(configurator)
            .to receive(:algolia)
          allow(configurator)
            .to receive(:algolia)
            .with('nodes_to_index')
            .and_return('div')
        end
        it { expect(subject.length).to eq 5 }
      end
    end
  end

  describe '.run' do
    subject { current.run(file) }

    context 'with mock data' do
      let!(:file) { site.__find_file('html.html') }
      before do
        allow(hooks)
          .to receive(:apply_each)
            .with(anything, anything) { |input| input }

        allow(current)
          .to receive(:extract_raw_records)
          .and_return(raw_records)

        allow(filebrowser)
          .to receive(:metadata)
          .and_return(metadata)
      end
      let(:raw_records) { [{}] }
      let(:metadata) { {} }

      describe 'should have one record per element extracted' do
        let(:raw_records) { [{ foo: 'bar' }, { baz: 'foo' }] }
        it { expect(subject.length).to eq 2 }
      end

      describe 'should all have the same common shared data' do
        let(:raw_records) { [{ foo: 'bar' }, { baz: 'foo' }] }
        let(:metadata) { { foo: 'bar' } }
        it { expect(subject[0]).to include(foo: 'bar') }
        it { expect(subject[1]).to include(foo: 'bar') }
      end

      describe 'should not contain a :node key' do
        let(:raw_records) { [{ foo: 'bar', node: 'nope' }] }
        it { expect(subject[0]).to_not include(:node) }
      end

      describe 'should not contain any nil or empty array keys' do
        let(:raw_records) { [{ foo: nil, bar: [] }] }
        let(:metadata) { { baz: nil, yep: 'yep' } }
        it do
          expect(subject[0]).to_not include(:foo)
          expect(subject[0]).to_not include(:bar)
          expect(subject[0]).to_not include(:baz)
          expect(subject[0]).to include(yep: 'yep')
        end
      end
    end

    context 'with real data' do
      let(:file) { site.__find_file('about.md') }

      describe 'should add a new key to each record' do
        it do
          expect(subject[0]).to include(added_through_each: true)
          expect(subject[1]).to include(added_through_each: true)
          expect(subject[2]).to include(added_through_each: true)
        end
      end
    end
  end

  describe '.add_unique_object_id' do
    subject { current.add_unique_object_id(record) }

    let(:record) { { foo: 'bar' } }
    let(:objectID) { nil }
    before do
      allow(AlgoliaHTMLExtractor)
        .to receive(:uuid)
        .and_return(:objectID)
    end

    it { expect(subject).to include(objectID: :objectID) }
  end
end
# rubocop:enable Metrics/BlockLength
