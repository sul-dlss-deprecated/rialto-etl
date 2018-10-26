# frozen_string_literal: true

require 'rialto/etl/transformers/addresses'
require 'rialto/etl/namespaces'

RSpec.describe Rialto::Etl::Transformers::Addresses do
  describe '.construct_country' do
    subject(:country_hash) do
      described_class.construct_country(country: country)
    end

    context 'when country is found' do
      let(:country) { 'USA' }

      it 'returns the correct hash' do
        expect(country_hash['@id']).to eq(Rialto::Etl::Vocabs::SWS_GEONAMES['6252001/'])
        expect(country_hash[RDF::Vocab::RDFS.label.to_s]).to eq('United States')
      end
    end

    context 'when additional country is found' do
      let(:country) { 'Wales' }

      it 'returns the correct hash' do
        expect(country_hash['@id']).to eq(Rialto::Etl::Vocabs::SWS_GEONAMES['2635167/'])
      end
    end

    context 'when country is not found' do
      let(:country) { 'foo' }

      it 'returns nil' do
        expect(country_hash).nil?
      end
    end
  end
end
