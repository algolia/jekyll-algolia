# frozen_string_literal: true

require 'spec_helper'
# rubocop:disable Metrics/BlockLength
describe(Jekyll::Algolia::Shrinker) do
  let(:current) { Jekyll::Algolia::Shrinker }
  let(:logger) { Jekyll::Algolia::Logger }
  let(:configurator) { Jekyll::Algolia::Configurator }
  let(:json) { ::JSON }

  describe '.size' do
    subject { current.size(input) }

    describe 'should return a fixed size for an empty object' do
      let(:input) { {} }
      it { should eq 2 }
    end

    describe 'should return a size in bytes' do
      let(:input) { { foo: 'bar' } }
      it { should eq 13 }
    end
  end

  describe '.fit_to_size' do
    subject { current.fit_to_size(input, max_file_size) }

    describe 'should not change anything if already under the limit' do
      let(:max_file_size) { 100_000 }
      let(:input) do
        {
          title: 'title'
        }
      end

      it { should eq input }
    end

    describe 'should stop if cannot be shrunk' do
      let(:max_file_size) { 20 }
      let(:input) do
        {
          title: 'title',
          html: '<p>This is long HTML</p>',
          content: 'This is long text'
        }
      end

      before do
        allow(current).to receive(:stop_with_error)
        current.fit_to_size(input, max_file_size)
      end

      it do
        expect(current)
          .to have_received(:stop_with_error)
          .with(input)
      end
    end

    describe 'should remove the html from the excerpt if too big' do
      let(:max_file_size) { 200 }
      let(:input) do
        # rubocop:disable Metrics/LineLength
        {
          title: 'title',
          excerpt_html: '<p>This is a long HTML excerpt. Lorem ipsum dolor sit amet, consectetur adipiscing elit.  Etiam lacus ligula, accumsan id imperdiet rhoncus, dapibus vitae arcu.  Nulla non quam erat, luctus consequat nisi</p>',
          excerpt_text: 'This is a short text excerpt'
        }
        # rubocop:enable Metrics/LineLength
      end

      it { expect(current.size(subject)).to be <= max_file_size }
      it do
        expect(subject[:excerpt_html]).to equal(subject[:excerpt_text])
      end
    end

    describe 'should halve the excerpt content if too big' do
      let(:max_file_size) { 200 }
      let(:input) do
        # rubocop:disable Metrics/LineLength
        {
          title: 'title',
          excerpt_html: '<p>This is a long HTML excerpt. Lorem ipsum dolor sit amet, consectetur adipiscing elit.  Etiam lacus ligula, accumsan id imperdiet rhoncus, dapibus vitae arcu.</p>',
          excerpt_text: 'This is also a long text excerpt. Lorem ipsum dolor sit amet, consectetur adipiscing elit.  Etiam lacus ligula, accumsan id imperdiet rhoncus, dapibus vitae arcu.'
        }
        # rubocop:enable Metrics/LineLength
      end
      let(:excerpt_size) { input[:excerpt_text].length }

      it { expect(current.size(subject)).to be <= max_file_size }
      it do
        expect(subject[:excerpt_text].size).to be < excerpt_size
      end
    end

    describe 'should completely remove the excerpts if they are too big' do
      let(:max_file_size) { 200 }
      let(:input) do
        # rubocop:disable Metrics/LineLength
        {
          title: 'title',
          excerpt_html: '<p>This is a long HTML excerpt. Lorem ipsum dolor sit amet, consectetur adipiscing elit.  Etiam lacus ligula, accumsan id imperdiet rhoncus, dapibus vitae arcu.  Nulla non quam erat, luctus consequat nisi. Lorem ipsum dolor sit amet, consectetur adipiscing elit.  Etiam lacus ligula, accumsan id imperdiet rhoncus, dapibus vitae arcu.</p>',
          excerpt_text: 'This is also a long text excerpt. Lorem ipsum dolor sit amet, consectetur adipiscing elit.  Etiam lacus ligula, accumsan id imperdiet rhoncus, dapibus vitae arcu.  Nulla non quam erat, luctus consequat nisi. Lorem ipsum dolor sit amet, consectetur adipiscing elit.  Etiam lacus ligula, accumsan id imperdiet rhoncus, dapibus vitae arcu.'
        }
        # rubocop:enable Metrics/LineLength
      end

      it { expect(current.size(subject)).to be <= max_file_size }
      it do
        expect(subject[:excerpt_text]).to eq nil
        expect(subject[:excerpt_html]).to eq nil
      end
    end

    describe 'should stop if cannot be reduced' do
      let(:max_file_size) { 20 }
      let(:input) do
        {
          title: 'title',
          html: '<p>This is a long HTML excerpt</p>',
          text: 'This is also a long text excerpt',
          excerpt_html: '<p>Remove me</p>',
          excerpt_text: 'Remove me'

        }
      end

      before do
        allow(current).to receive(:stop_with_error)
        current.fit_to_size(input, max_file_size)
      end

      it do
        # We still remove the excerpts from the record
        updated_record = input.clone
        updated_record.delete(:excerpt_html)
        updated_record.delete(:excerpt_text)
        expect(current)
          .to have_received(:stop_with_error)
          .with(updated_record)
      end
    end
  end

  describe '.stop_process' do
    subject { -> { current.stop_process } }
    it { is_expected.to raise_error SystemExit }
  end

  describe '.stop_with_error' do
    let(:record) { {} }

    before do
      allow(current).to receive(:stop_process)
      allow(logger).to receive(:write_to_file) do |filepath, _|
        filepath
      end
      allow(logger).to receive(:known_message)
    end

    describe 'should stop the process' do
      before { current.stop_with_error(record) }

      it do
        expect(current).to have_received(:stop_process)
      end
    end

    describe 'should save a log file' do
      before do
        allow(json).to receive(:pretty_generate).and_return('{json}')
      end

      before { current.stop_with_error(record) }

      it do
        expect(logger)
          .to have_received(:write_to_file)
          .with('jekyll-algolia-record-too-big.log', '{json}')
      end
    end

    describe 'should display the error message' do
      let(:record) do
        {
          title: 'Title',
          url: '/url'
        }
      end
      before do
        allow(current)
          .to receive(:readable_largest_record_keys)
          .and_return('bad keys')
        allow(configurator)
          .to receive(:algolia)
        allow(configurator)
          .to receive(:algolia)
          .with('nodes_to_index')
          .and_return('my_nodes')
        allow(configurator)
          .to receive(:algolia)
          .with('max_record_size')
          .and_return('45000')
      end
      before { current.stop_with_error(record) }

      it do
        expect(logger).to have_received(:known_message)
          .with('record_too_big',
                'object_title' => 'Title',
                'object_url' => '/url',
                'probable_wrong_keys' => 'bad keys',
                'record_log_path' => 'jekyll-algolia-record-too-big.log',
                'nodes_to_index' => 'my_nodes',
                'record_size' => '0.03 Kb',
                'max_record_size' => '45.00 Kb')
      end
    end
  end

  describe '.readable_largest_record_keys' do
    let(:record) { { foo: foo, bar: bar, baz: baz, small: 'xxx' } }
    let(:foo) { 'x' * 1000 }
    let(:bar) { 'x' * 10_000 }
    let(:baz) { 'x' * 100_000 }

    subject { current.readable_largest_record_keys(record) }

    it { should eq 'baz (100.00 Kb), bar (10.00 Kb), foo (1.00 Kb)' }
  end
end
# rubocop:enable Metrics/BlockLength
