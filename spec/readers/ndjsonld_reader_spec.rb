# frozen_string_literal: true

require 'rialto/etl/readers/ndjsonld_reader'

RSpec.describe Rialto::Etl::Readers::NDJsonLDReader do
  subject(:instance) { described_class.new(reader, settings) }

  let(:reader) { File.open('spec/fixtures/organizations.ndjsonld', 'r') }
  let(:settings) { {} }

  describe '#decode' do
    subject { instance.decode(row, 1) }

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

    it { is_expected.to be_kind_of RDF::Graph }
  end
end
