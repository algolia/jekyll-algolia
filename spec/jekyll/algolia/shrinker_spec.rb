# frozen_string_literal: true

require 'spec_helper'
# rubocop:disable Metrics/BlockLength
describe(Jekyll::Algolia::Shrinker) do
  let(:current) { Jekyll::Algolia::Shrinker }

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

    describe 'should not change anything if cannot be shrunk' do
      let(:max_file_size) { 200 }
      let(:input) do
        # rubocop:disable Metrics/LineLength
        {
          title: 'title',
          html: '<p>This is a long HTML excerpt. Lorem ipsum dolor sit amet, consectetur adipiscing elit.  Etiam lacus ligula, accumsan id imperdiet rhoncus, dapibus vitae arcu.  Nulla non quam erat, luctus consequat nisi. Lorem ipsum dolor sit amet, consectetur adipiscing elit.  Etiam lacus ligula, accumsan id imperdiet rhoncus, dapibus vitae arcu.</p>',
          content: 'This is also a long text excerpt. Lorem ipsum dolor sit amet, consectetur adipiscing elit.  Etiam lacus ligula, accumsan id imperdiet rhoncus, dapibus vitae arcu.  Nulla non quam erat, luctus consequat nisi. Lorem ipsum dolor sit amet, consectetur adipiscing elit.  Etiam lacus ligula, accumsan id imperdiet rhoncus, dapibus vitae arcu.'
        }
        # rubocop:enable Metrics/LineLength
      end

      it { should eq input }
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
  end
end
# rubocop:enable Metrics/BlockLength
