# frozen_string_literal: true

require 'rialto/etl/loaders/sparql'

RSpec.describe Rialto::Etl::Loaders::Sparql do
  subject(:loader) { described_class.new(input: path) }

  let(:path) { 'spec/fixtures/rdf.nt' }
  let(:input) { '' }

  describe '#load' do
    before do
      allow(Traject::Indexer).to receive(:new).and_return(indexer)
      allow(RDF::Reader).to receive(:open).and_yield(input)
    end

    let(:indexer) { instance_double(Traject::Indexer, load_config_file: true) }

    it 'passes input to the indexer' do
      allow(indexer).to receive(:process)
      loader.load
      expect(indexer).to have_received(:load_config_file).with('lib/rialto/etl/configs/sparql.rb')
      expect(indexer).to have_received(:process).with(input).once
    end
  end
end
