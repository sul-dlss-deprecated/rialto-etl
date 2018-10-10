# frozen_string_literal: true

require 'rialto/etl/transformers/addresses'
require 'rialto/etl/namespaces'

RSpec.describe Rialto::Etl::Transformers::Addresses do
  describe '.geocode_for_country' do
    subject(:geocode) do
      described_class.geocode_for_country(country: country)
    end

    context 'when country is found' do
      let(:country) { 'USA' }

      it 'returns the correct geocode' do
        expect(geocode).to eq(Rialto::Etl::Vocabs::SWS_GEONAMES['6252001/'])
      end
    end

    context 'when additional country is found' do
      let(:country) { 'Wales' }

      it 'returns the correct geocode' do
        expect(geocode).to eq(Rialto::Etl::Vocabs::SWS_GEONAMES['2635167/'])
      end
    end

    context 'when country is not found' do
      let(:country) { 'foo' }

      it 'returns nil' do
        expect(geocode).nil?
      end
    end
  end
end
