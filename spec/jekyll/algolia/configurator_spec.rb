# rubocop:disable Metrics/BlockLength
require 'spec_helper'

describe(Jekyll::Algolia::Configurator) do
  let(:current) { Jekyll::Algolia::Configurator }
  before do
    allow(Jekyll::Algolia).to receive(:config).and_return(config)
  end

  describe '.get' do
    let(:config) { { 'foo' => 'bar' } }

    subject { current.get('foo') }

    it { should eq 'bar' }
  end

  describe '.algolia' do
    subject { current.algolia(input) }

    context 'with an algolia config defined' do
      let(:config) { { 'algolia' => { 'foo' => 'bar' } } }

      context 'with a config option that is set' do
        let(:input) { 'foo' }
        it { should eq 'bar' }
      end
      context 'with a config option that is not set' do
        let(:input) { 'baz' }
        it { should eq nil }
      end
      describe 'should get the default nodes_to_index' do
        let(:input) { 'nodes_to_index' }
        it { should eq 'p' }
      end
      describe 'should get the default extensions_to_index' do
        before(:each) do
          allow(current)
            .to receive(:default_extensions_to_index)
            .and_return('foo')
        end

        let(:input) { 'extensions_to_index' }
        it { should eq 'foo' }
      end
    end

    context 'with no algolia config defined' do
      let(:config) { {} }
      let(:input) { 'foo' }
      it { should eq nil }

      describe 'should get the default nodes_to_index' do
        let(:input) { 'nodes_to_index' }
        it { should eq 'p' }
      end
    end
  end

  describe '.default_extensions_to_index' do
    let(:config) { {} }

    subject { current.default_extensions_to_index }

    before do
      allow(current)
        .to receive(:get)
        .with('markdown_ext')
        .and_return('foo,bar')
    end

    it { should include('html') }
    it { should include('foo') }
    it { should include('bar') }
  end

  describe '.default_files_to_exclude' do
    let(:config) { {} }

    subject { current.default_files_to_exclude }

    before do
      allow(current)
        .to receive(:algolia)
        .with('extensions_to_index')
        .and_return(%w[foo bar])
    end

    it { should include('index.foo') }
    it { should include('index.bar') }
  end
end
