# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable Metrics/BlockLength
describe(Jekyll::Algolia::Extractor) do
  let(:configurator) { Jekyll::Algolia::Configurator }
  let(:filebrowser) { Jekyll::Algolia::FileBrowser }
  let(:hooks) { Jekyll::Algolia::Hooks }
  let(:current) { Jekyll::Algolia::Extractor }
  let(:site) { init_new_jekyll_site }

  # Suppress Jekyll log
  before do
    allow(Jekyll.logger).to receive(:info)
    allow(Jekyll.logger).to receive(:warn)
  end
  # Do not exit on wrong Algolia configuration
  before do
    allow(Jekyll::Algolia::Configurator)
      .to receive(:assert_valid_credentials)
      .and_return(true)
  end

  describe '.extract_raw_records' do
    let(:nodes_to_index) { 'p' }
    let(:content) { init_new_jekyll_site.__find_file(filename).content }

    subject { current.extract_raw_records(content) }

    before do
      allow(configurator).to receive(:algolia).and_call_original
      allow(configurator)
        .to receive(:algolia)
        .with('nodes_to_index')
        .and_return(nodes_to_index)
    end

    describe 'should call the underlying extractor' do
      let(:content) { 'some html markup' }

      before do
        expect(AlgoliaHTMLExtractor)
          .to receive(:run)
          .with(
            content,
            options: hash_including(css_selector: nodes_to_index)
          )
          .and_return([{ name: 'record' }])
      end

      it { expect(subject[0]).to include(name: 'record') }
    end

    describe do
      let(:filename) { 'only-paragraphs.md' }
      let(:nodes_to_index) { 'div' }
      it { expect(subject.length).to eq 0 }
    end

    describe do
      let(:filename) { 'only-divs.md' }
      let(:nodes_to_index) { 'div' }
      it { expect(subject.length).to eq 6 }
    end

    describe do
      let(:content) do
        '<h1>Main title</h1>
         <h2>Subtitle</h2>
         <p>My text</p>'
      end

      it do
        expect(subject[0]).to include(html: '<p>My text</p>')
        expect(subject[0]).to include(content: 'My text')
        expect(subject[0]).to_not include(:weight)
        expect(subject[0]).to include(custom_ranking: {
                                        position: 0,
                                        heading: 80
                                      })
        expect(subject[0]).to_not include(:tag_name)
      end
    end
  end

  describe '.run' do
    subject { current.run(file) }

    context 'with mock data' do
      let(:file) { double('File', content: nil) }
      before do
        allow(hooks)
          .to receive(:apply_each)
            .with(anything, anything, anything) { |input| input }

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

      describe 'should not contain any nil' do
        let(:raw_records) { [{ foo: nil }] }
        let(:metadata) { { bar: nil, yep: 'yep' } }
        it do
          expect(subject[0]).to_not include(:foo)
          expect(subject[0]).to_not include(:bar)
          expect(subject[0]).to include(yep: 'yep')
        end
      end

      describe 'should keep empty arrays' do
        let(:raw_records) { [{ foo: [] }] }
        let(:metadata) { {} }
        it do
          expect(subject[0]).to include(:foo)
        end
      end

      describe 'should create a record with metadata only if no content' do
        let(:raw_records) { [] }
        let(:metadata) { { name: 'foo' } }
        it do
          expect(subject[0]).to eq metadata
        end
      end

      describe 'should call apply_each on each record' do
        let(:node) { double('Node') }
        let(:hook_context) { double('Context') }
        let(:raw_records) { [{ name: 'foo', node: node }] }
        let(:metadata) { { url: '/url/' } }
        before do
          allow(Jekyll::Algolia).to receive(:site).and_return(hook_context)

          current.run(file)
        end

        it do
          expect(hooks)
            .to have_received(:apply_each)
            .with(
              { name: 'foo', url: '/url/' },
              node,
              hook_context
            )
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
