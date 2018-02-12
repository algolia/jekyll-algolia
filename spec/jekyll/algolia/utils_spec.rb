# frozen_string_literal: true

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
    context 'with nil content' do
      let(:html) { nil }
      let(:expected) { nil }
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

  describe '.match?' do
    subject { current.match?(string, regexp) }
    let(:string) { 'foo-42-bar' }

    context 'with a matching regexp' do
      let(:regexp) { /^foo-([0-9]*)-bar$/ }
      it { should eq true }
    end
    context 'with a non-matching regexp' do
      let(:regexp) { /^foo-([0-9]*)-baz$/ }
      it { should eq false }
    end
  end

  describe '.find_by_key' do
    subject { current.find_by_key(items, 'key', 'value') }

    context 'with an empty array' do
      let(:items) { [] }
      it { should eq nil }
    end
    context 'with a nil value' do
      let(:items) { nil }
      it { should eq nil }
    end
    context 'with a non-existing value' do
      let(:items) { [{ 'key' => 'foo' }] }
      it { should eq nil }
    end
    context 'with an existing value' do
      let(:items) { [{ 'key' => 'value' }] }
      it { should include('key' => 'value') }
    end
  end
end
# rubocop:enable Metrics/BlockLength
