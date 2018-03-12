# frozen_string_literal: true

require 'spec_helper'

describe(Jekyll::Algolia::Hooks) do
  let(:current) { Jekyll::Algolia::Hooks }

  describe '.apply_each' do
    subject { current.apply_each(record, node) }

    let(:record) { { foo: 'bar' } }
    let(:node) { double('Nokogiri Node') }
    let(:record_after_hook) { {} }

    before do
      expect(current)
        .to receive(:before_indexing_each)
        .with(record, node)
        .and_return(record_after_hook)
    end

    it { should eq record_after_hook }
  end

  describe '.apply_all' do
    subject { current.apply_all(records) }

    let(:records) { [{ foo: 'bar' }, { foo: 'baz' }] }
    let(:records_after_hook) { {} }

    before do
      expect(current)
        .to receive(:before_indexing_all)
        .with(records)
        .and_return(records_after_hook)
    end

    it { should eq records_after_hook }
  end
end
