# rubocop:disable Metrics/BlockLength
require 'spec_helper'

describe(Jekyll::Algolia::Utils) do
  let(:current) { Jekyll::Algolia::Utils }

  describe '.html_to_text' do
    subject { current.html_to_text(html) }

    context 'with simple html' do
      let(:html) { '<p>This is content</p>' }
      let(:expected) { 'This is content' }
      it { should eq expected }
    end
    context 'with trailing spaces' do
      let(:html) { '<p>This is content</p>      ' }
      let(:expected) { 'This is content' }
      it { should eq expected }
    end
    context 'with additional spaces' do
      let(:html) { '<p>This is        content</p>' }
      let(:expected) { 'This is content' }
      it { should eq expected }
    end
    context 'with new lines' do
      let(:html) { "<p>This \n is \n content</p>" }
      let(:expected) { 'This is content' }
      it { should eq expected }
    end
  end

  describe '.keys_to_symbols' do
    let(:expected) { { foo: 'bar', bar: 'baz' } }

    subject { current.keys_to_symbols(hash) }

    context 'with a hash of symbols' do
      let(:hash) { { foo: 'bar', bar: 'baz' } }
      it { should include(foo: 'bar') }
      it { should include(bar: 'baz') }
    end
    context 'with a hash of strings' do
      let(:hash) { { 'foo' => 'bar', 'bar' => 'baz' } }
      it { should include(foo: 'bar') }
      it { should include(bar: 'baz') }
    end
    context 'with a mixed hash of strings and symbols' do
      let(:hash) { { 'foo' => 'bar', bar: 'baz' } }
      it { should include(foo: 'bar') }
      it { should include(bar: 'baz') }
    end
  end

  describe '.compact_empty' do
    subject { current.compact_empty(input) }

    context 'with nil keys' do
      let(:input) { { foo: 'bar', bar: nil } }
      let(:expected) { { foo: 'bar' } }
      it { should eq expected }
    end
    context 'with empty arrays' do
      let(:input) { { foo: 'bar', bar: [] } }
      let(:expected) { { foo: 'bar' } }
      it { should eq expected }
    end
    context 'with false values' do
      let(:input) { { foo: 'bar', bar: false } }
      let(:expected) { { foo: 'bar', bar: false } }
      it { should eq expected }
    end
  end
end
