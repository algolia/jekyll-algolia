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
end
