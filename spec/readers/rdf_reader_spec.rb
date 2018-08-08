# frozen_string_literal: true

require 'rialto/etl/readers/rdf_reader'

RSpec.describe Rialto::Etl::Readers::RDFReader do
  subject(:instance) { described_class.new(reader, settings) }

  let(:reader) { RDF::Reader.open('spec/fixtures/rdf.nt') }
  let(:settings) { {} }

  describe '#each' do
    it 'calls each_statement on the reader' do
      count = 0
      instance.each { |_statement| count += 1 }
      expect(count).to eq 3
    end
  end
end
