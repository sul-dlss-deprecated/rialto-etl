# frozen_string_literal: true

require 'rialto/etl/writers/sparql_writer'

RSpec.describe Rialto::Etl::Writers::SparqlWriter do
  describe 'writing' do
    let(:client) { instance_double(SPARQL::Client, insert_data: true) }
    let(:writer) { described_class.new('sparql_writer.client' => client) }
    let(:source) { RDF::Statement.new(:hello, RDF::RDFS.label, 'Hello, world!') }
    let(:context) do
      Traject::Indexer::Context.new(output_hash: hash, source_record: source)
    end

    it 'writes to the SPARQL' do
      writer.put context
      writer.close
      expect(client).to have_received(:insert_data)
    end
  end
end
