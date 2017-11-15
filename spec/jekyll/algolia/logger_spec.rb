# rubocop:disable Metrics/BlockLength
require 'spec_helper'

describe(Jekyll::Algolia::Logger) do
  let(:current) { Jekyll::Algolia::Logger }
  let(:configurator) { Jekyll::Algolia::Configurator }
  describe '.known_message' do
    let(:io) { double('IO', readlines: lines) }
    let(:lines) do
      [
        'I: Info line',
        'W: Warning line',
        'E: Error line'
      ]
    end
    before do
      expect(File)
        .to receive(:open)
        .with(/custom_message\.txt$/)
        .and_return(io)
      expect(current).to receive(:log).with('I: Info line')
      expect(current).to receive(:log).with('W: Warning line')
      expect(current).to receive(:log).with('E: Error line')
    end

    it { current.known_message('custom_message') }
  end

  describe '.log' do
    context 'with an error line' do
      let(:input) { 'E: Error line' }
      before do
        expect(Jekyll.logger)
          .to receive(:error)
          .with(/Error line/)
      end
      it { current.log(input) }
    end
    context 'with a warning line' do
      let(:input) { 'W: Warning line' }
      before do
        expect(Jekyll.logger)
          .to receive(:warn)
          .with(/Warning line/)
      end
      it { current.log(input) }
    end
    context 'with an information line' do
      let(:input) { 'I: Information line' }
      before do
        expect(Jekyll.logger)
          .to receive(:info)
          .with(/Information line/)
      end
      it { current.log(input) }
    end

    context 'with regular type' do
      let(:input) { 'I: Information line' }
      before do
        expect(Jekyll.logger)
          .to receive(:info)
          .with(/^.{80,80}$/)
      end
      it { current.log(input) }
    end
  end

  describe '.verbose' do
    before do
      allow(configurator).to receive(:verbose?).and_return(is_verbose)
    end
    before { allow(current).to receive(:log) }
    before { current.verbose('foo') }

    context 'when verbose is disabled' do
      let(:is_verbose) { false }
      it do
        expect(current)
          .to_not have_received(:log)
          .with('foo')
      end
    end
    context 'when verbose is enabled' do
      let(:is_verbose) { true }
      it do
        expect(current)
          .to have_received(:log)
          .with('foo')
      end
    end
  end
end
