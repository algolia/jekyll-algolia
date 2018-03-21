# frozen_string_literal: true

require 'spec_helper'

describe(Jekyll::Algolia::Hooks) do
  let(:current) { Jekyll::Algolia::Hooks }

  describe '.apply_each' do
    subject { current.apply_each(record, node, context) }

    let(:record) { { foo: 'bar' } }
    let(:node) { double('Nokogiri Node') }
    let(:context) { double('Jekyll Context') }
    let(:record_after_hook) { {} }

    before do
      expect(current)
        .to receive(:before_indexing_each)
        .with(record, node, context)
        .and_return(record_after_hook)
    end

    it { should eq record_after_hook }
  end

  describe '.apply_all' do
    subject { current.apply_all(records, context) }

    let(:records) { [{ foo: 'bar' }, { foo: 'baz' }] }
    let(:context) { double('Jekyll Context') }
    let(:records_after_hook) { {} }

    before do
      expect(current)
        .to receive(:before_indexing_all)
        .with(records, context)
        .and_return(records_after_hook)
    end

    it { should eq records_after_hook }
  end
end
