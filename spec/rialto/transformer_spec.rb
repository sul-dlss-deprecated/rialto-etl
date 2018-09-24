# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rialto::Etl::Transformer do
  subject(:transformer) { described_class.new(input_stream: input_stream, config_file_path: config_file_path) }

  let(:input_stream) { StringIO.new('') }
  let(:config_file_path) { '' }

  describe '#input_stream' do
    it 'returns the value of the passed-in attr' do
      expect(transformer.input_stream).to eq input_stream
    end
  end

  describe '#transform' do
    before do
      allow(transformer).to receive(:transformer).and_return(indexer)
    end

    let(:indexer) { instance_double(Traject::Indexer) }

    it 'passes input to the indexer' do
      allow(indexer).to receive(:process)
      transformer.transform
      expect(indexer).to have_received(:process).with(input_stream).once
    end
  end

  describe '#transformer' do
    let(:indexer) { instance_double(Traject::Indexer, process: nil) }

    it 'returns an instance of Traject::Indexer with the specified config' do
      allow(Traject::Indexer).to receive(:new).and_return(indexer)
      allow(indexer).to receive(:load_config_file).with(config_file_path)
      transformer.transform
      expect(Traject::Indexer).to have_received(:new).once
      expect(indexer).to have_received(:load_config_file).once
    end
  end
end
