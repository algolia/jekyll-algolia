# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable Metrics/BlockLength
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

  describe '.instance_of?' do
    subject { current.instance_of?(input, classname) }

    context do
      let(:input) { 'foo' }
      let(:classname) { 'String' }
      it { should eq true }
    end
    context do
      let(:input) { 42 }
      let(:classname) { 'String' }
      it { should eq false }
    end
    context do
      let(:input) { 'foo' }
      let(:classname) { 'Foo' }
      it { should eq false }
    end
    context do
      let(:input) { 'foo' }
      let(:classname) { 'Foo::SubFoo' }
      it { should eq false }
    end
    context do
      let(:input) { Foo.new   }
      let(:classname) { 'Foo' }
      before do
        stub_const 'Foo', Class.new
      end
      it { should eq true }
    end
    context do
      let(:input) { Foo::SubFoo.new   }
      let(:classname) { 'Foo::SubFoo' }
      before do
        stub_const 'Foo::SubFoo', Class.new
      end
      it { should eq true }
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

  describe '.jsonify' do
    subject { current.jsonify(item) }

    context 'with a string' do
      let(:item) { 'foo' }
      it { should eq 'foo' }
    end
    context 'with a number' do
      let(:item) { 42 }
      it { should eq 42 }
    end
    context 'with a boolean (true)' do
      let(:item) { true }
      it { should eq true }
    end
    context 'with a boolean (false)' do
      let(:item) { false }
      it { should eq false }
    end
    context 'with an array' do
      let(:item) { %w[foo bar] }
      it { should eq %w[foo bar] }
    end
    context 'with a recursive array' do
      let(:item) { ['foo', ['bar']] }
      it { should eq ['foo', ['bar']] }
    end
    context 'with an object' do
      let(:item) { { foo: 'bar' } }
      it { should eq item }
    end
    context 'with a recursive object' do
      let(:item) { { foo: { bar: 'baz' } } }
      it { should eq item }
    end
    context 'with a stringifiable custom object' do
      let(:item) { double('Custom::Object', to_s: 'foo') }
      it { should eq 'foo' }
    end
    context 'with a non-stringifiable custom object' do
      let(:item) do
        # rubocop:disable Style/EvalWithLocation
        fake_object = double('Custom::Object')
        fake_object.instance_eval('undef :to_s')
        fake_object
        # rubocop:enable Style/EvalWithLocation
      end
      it { should eq nil }
    end
    fcontext 'with an asciidoc object' do
      let(:to_s) do
        # rubocop:disable Metrics/LineLength
        '#<Asciidoctor::Document@33306360 {doctype: "article", doctitle: nil, blocks: 11}>'
        # rubocop:enable Metrics/LineLength
      end
      let(:item) { double('Custom::Object', to_s: to_s) }
      it { should eq nil }
    end
  end
end
# rubocop:enable Metrics/BlockLength
