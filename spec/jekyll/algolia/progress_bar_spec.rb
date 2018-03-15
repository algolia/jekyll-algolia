# frozen_string_literal: true

require 'spec_helper'
describe(Jekyll::Algolia::ProgressBar) do
  let(:current) { Jekyll::Algolia::ProgressBar }
  let(:configurator) { Jekyll::Algolia::Configurator }

  describe '.should_be_silenced?' do
    before do
      allow(configurator).to receive(:verbose?).and_return(verbose)
    end

    subject { current.should_be_silenced? }

    describe do
      let(:verbose) { true }
      it { should eq true }
    end
    describe do
      let(:verbose) { false }
      it { should eq false }
    end
  end

  describe '.create' do
    let(:progress_bar_instance) { nil }
    let(:open_struct_instance) { double('OpenStruct', :increment= => nil) }
    let(:options) { 'options' }

    subject { current.create(options) }

    before do
      allow(current).to receive(:should_be_silenced?).and_return(silenced)
      allow(::ProgressBar).to receive(:create).and_return(progress_bar_instance)
      allow(::OpenStruct).to receive(:new).and_return(open_struct_instance)
    end

    describe 'when not silenced' do
      let(:silenced) { false }

      before do
        expect(::ProgressBar)
          .to receive(:create)
          .with(options)
      end

      it 'should return a real progress bar' do
        should eq progress_bar_instance
      end
    end

    describe 'when silenced' do
      let(:silenced) { true }

      before do
        expect(::OpenStruct)
          .to receive(:new)
      end

      it 'should return a fake progress bar' do
        should eq open_struct_instance
      end
    end
  end
end
