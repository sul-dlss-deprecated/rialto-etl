# frozen_string_literal: true

require 'rialto/etl/transformers/people'

RSpec.describe Rialto::Etl::Transformers::People do
  describe '.construct_positions' do
    subject(:positions) { described_class.construct_positions(titles: titles, profile_id: id) }

    let(:id) { '123' }

    context 'when titles are present' do
      let(:titles) do
        [{
          'label' => {
            'text' => 'UX Designer, SoM - Information Resources & Technology'
          },
          'organization' => {
            'orgCode' => 'VRTS'
          },
          'title' => 'UX Designer'
        }]
      end

      it 'returns positions' do
        position = positions.first
        expect(position['@id']).to eq RDF::URI('http://sul.stanford.edu/rialto/context/positions/VRTS_123')
        expect(position['@type']).to eq RDF::URI('http://vivoweb.org/ontology/core#Position')
        expect(position['http://vivoweb.org/ontology/core#relates'][0])
          .to eq RDF::URI('http://sul.stanford.edu/rialto/agents/people/123')
        expect(position['http://vivoweb.org/ontology/core#relates'][1])
          .to include('@id' => RDF::URI('http://sul.stanford.edu/rialto/agents/orgs/school-of-medicine/deans-office/information-resources-and-technology-irt/it-services'))
      end
    end

    context 'when titles are nil' do
      let(:titles) { nil }

      it 'returns positions' do
        expect(positions).to eq []
      end
    end
  end
end
