# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable Metrics/BlockLength
describe(Jekyll::Algolia::Hooks) do
  let(:current) { Jekyll::Algolia::Hooks }

  describe '.apply_each' do
    let(:record) { { name: 'foo' } }
    let(:node) { double('Node') }
    let(:context) { double('Context') }
    let(:hook_return) { 'hook_return' }
    let(:arity) { 3 }

    before do
      allow(current)
        .to receive(:before_indexing_each)
        .and_return(hook_return)
      allow(current)
        .to receive(:method)
        .with(:before_indexing_each)
        .and_return(double('Hook', arity: arity))
    end

    describe 'should return the hook result' do
      subject { current.apply_each(record, node, context) }
      it { should eq hook_return }
    end

    describe 'with a hook with three parameters' do
      before { current.apply_each(record, node, context) }

      it do
        expect(current)
          .to have_received(:before_indexing_each)
          .with(record, node, context)
      end
    end

    describe 'with a hook with two parameters' do
      let(:arity) { 2 }

      before { current.apply_each(record, node, context) }

      it do
        expect(current)
          .to have_received(:before_indexing_each)
          .with(record, node)
      end
    end
  end

  describe '.apply_all' do
    let(:records) { [{ name: 'foo' }] }
    let(:context) { double('Context') }
    let(:hook_return) { 'hook_return' }
    let(:arity) { 2 }

    before do
      allow(current)
        .to receive(:before_indexing_all)
        .and_return(hook_return)
      allow(current)
        .to receive(:method)
        .with(:before_indexing_all)
        .and_return(double('Hook', arity: arity))
    end

    describe 'should return the hook result' do
      subject { current.apply_all(records, context) }
      it { should eq hook_return }
    end

    describe 'with a hook with two parameters' do
      before { current.apply_all(records, context) }

      it do
        expect(current)
          .to have_received(:before_indexing_all)
          .with(records, context)
      end
    end

    describe 'with a hook with one parameters' do
      let(:arity) { 1 }

      before { current.apply_all(records, context) }

      it do
        expect(current)
          .to have_received(:before_indexing_all)
          .with(records)
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
