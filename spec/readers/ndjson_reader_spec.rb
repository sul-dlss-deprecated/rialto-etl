# frozen_string_literal: true

require 'rialto/etl/readers/ndjsonld_reader'

RSpec.describe Rialto::Etl::Readers::NDJsonReader do
  subject(:instance) { described_class.new(reader, settings) }

  let(:reader) { File.open('spec/fixtures/organizations.ndj', 'r') }
  let(:settings) { {} }

  let(:logger) { instance_double('Yell::Logger') }

  describe '#each' do
    it 'calls each once for each line in the file' do
      count = 0
      instance.each { |_statement| count += 1 }
      expect(count).to eq 31
    end
  end

  describe '#decode' do
    subject(:decode) { instance.decode(row, 1) }

    let(:row) do
      <<-DOCUMENT
      {"@id":"http://rialto.stanford.edu/organizations/stanford",
       "@type":"http://vivoweb.org/ontology/core#University",
       "http://www.w3.org/2000/01/rdf-schema#label":"Stanford University",
       "http://vivoweb.org/ontology/core#abbreviation":["AA00"],
       "http://dbpedia.org/ontology/alias":"stanford",
       "@context":{"parent":{"@id":"http://purl.obolibrary.org/obo/BFO_0000050","@type":"@id"}}}
      DOCUMENT
    end

    it { is_expected.to be_kind_of Hash }

    context 'when an error occurs' do
      let(:row) { '{' }

      before do
        allow_any_instance_of(described_class).to receive(:logger).and_return(logger)
        allow(logger).to receive(:error)
      end

      it 'logs an error' do
        expect { decode }.not_to raise_error
        expect(logger).to have_received(:error).with("Problem with JSON record on line 1: 765: unexpected token at '{'")
      end
    end
  end
end
