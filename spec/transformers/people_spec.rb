# frozen_string_literal: true

require 'rialto/etl/transformers/people'
require 'rialto/etl/namespaces'

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
  describe '.construct_address_vcard' do
    subject(:vcard) do
      described_class.construct_address_vcard(id, street_address: address,
                                                  locality: city,
                                                  region: state,
                                                  postal_code: zip,
                                                  country: country)
    end

    let(:id) { '123' }

    context 'when address is provided' do
      let(:address) { '557 Escondido Mall' }

      let(:city) { 'Stanford' }

      let(:state) { 'CA' }

      let(:zip) { '94305' }

      let(:country) { 'USA' }

      it 'returns address vcard hash' do
        expect(vcard).to eq(
          '@id' => Rialto::Etl::Vocabs::RIALTO_CONTEXT_ADDRESSES['123'],
          '@type' => Rialto::Etl::Vocabs::VCARD['Address'],
          "!#{Rialto::Etl::Vocabs::VCARD['street-address']}" => true,
          "!#{Rialto::Etl::Vocabs::VCARD['locality']}" => true,
          "!#{Rialto::Etl::Vocabs::VCARD['region']}" => true,
          "!#{Rialto::Etl::Vocabs::VCARD['country-name']}" => true,
          "!#{Rialto::Etl::Vocabs::VCARD['postal-code']}" => true,
          "!#{Rialto::Etl::Vocabs::DCTERMS['spatial']}" => true,
          Rialto::Etl::Vocabs::VCARD['street-address'].to_s => '557 Escondido Mall',
          Rialto::Etl::Vocabs::VCARD['locality'].to_s => 'Stanford',
          Rialto::Etl::Vocabs::VCARD['region'].to_s => 'CA',
          Rialto::Etl::Vocabs::VCARD['postal-code'].to_s => '94305',
          Rialto::Etl::Vocabs::VCARD['country-name'].to_s => 'USA',
          Rialto::Etl::Vocabs::DCTERMS['spatial'].to_s => Rialto::Etl::Vocabs::GEONAMES['6252001/']
        )
      end
      context 'when country only is provided' do
        let(:address) { nil }

        let(:city) { nil }

        let(:state) { nil }

        let(:zip) { nil }

        let(:country) { 'Wales' }

        it 'returns address vcard hash' do
          expect(vcard).to eq(
            '@id' => Rialto::Etl::Vocabs::RIALTO_CONTEXT_ADDRESSES['123'],
            '@type' => Rialto::Etl::Vocabs::VCARD['Address'],
            "!#{Rialto::Etl::Vocabs::VCARD['street-address']}" => true,
            "!#{Rialto::Etl::Vocabs::VCARD['locality']}" => true,
            "!#{Rialto::Etl::Vocabs::VCARD['region']}" => true,
            "!#{Rialto::Etl::Vocabs::VCARD['country-name']}" => true,
            "!#{Rialto::Etl::Vocabs::VCARD['postal-code']}" => true,
            "!#{Rialto::Etl::Vocabs::DCTERMS['spatial']}" => true,
            Rialto::Etl::Vocabs::VCARD['country-name'].to_s => 'Wales',
            Rialto::Etl::Vocabs::DCTERMS['spatial'].to_s => Rialto::Etl::Vocabs::GEONAMES['2635167/']
          )
        end
      end
    end
  end
  describe '.construct_name_vcard' do
    subject(:vcard) do
      described_class.construct_name_vcard(id: id, given_name: given_name, middle_name: middle_name, family_name: family_name)
    end

    let(:given_name) { 'Justin' }

    let(:family_name) { 'Littman' }

    context 'when middle name and id provided' do
      let(:middle_name) { 'Cunningham' }

      let(:id) { '123' }

      it 'returns the correct fullname' do
        expect(vcard).to eq(
          '@id' => Rialto::Etl::Vocabs::RIALTO_CONTEXT_NAMES['123'],
          '@type' => Rialto::Etl::Vocabs::VCARD['Name'],
          "!#{Rialto::Etl::Vocabs::VCARD['given-name']}" => true,
          "!#{Rialto::Etl::Vocabs::VCARD['middle-name']}" => true,
          "!#{Rialto::Etl::Vocabs::VCARD['family-name']}" => true,
          Rialto::Etl::Vocabs::VCARD['given-name'].to_s => 'Justin',
          Rialto::Etl::Vocabs::VCARD['middle-name'].to_s => 'Cunningham',
          Rialto::Etl::Vocabs::VCARD['family-name'].to_s => 'Littman'
        )
      end
      context 'when middle name and id not provided' do
        let(:middle_name) { nil }

        let(:id) { nil }

        it 'returns the correct fullname' do
          expect(vcard).to eq(
            '@id' => Rialto::Etl::Vocabs::RIALTO_CONTEXT_NAMES['ed1aa059391f675499eda6172ddc29f4'],
            '@type' => Rialto::Etl::Vocabs::VCARD['Name'],
            "!#{Rialto::Etl::Vocabs::VCARD['given-name']}" => true,
            "!#{Rialto::Etl::Vocabs::VCARD['middle-name']}" => true,
            "!#{Rialto::Etl::Vocabs::VCARD['family-name']}" => true,
            Rialto::Etl::Vocabs::VCARD['given-name'].to_s => 'Justin',
            Rialto::Etl::Vocabs::VCARD['family-name'].to_s => 'Littman'
          )
        end
      end
    end
  end

  describe '.fullname_from_names' do
    subject(:fullname) do
      described_class.fullname_from_names(given_name: given_name, middle_name: middle_name, family_name: family_name)
    end

    let(:given_name) { 'Justin' }

    let(:family_name) { 'Littman' }

    context 'when middle name is provided' do
      let(:middle_name) { 'Cunningham' }

      it 'returns the correct fullname' do
        expect(fullname).to eq('Justin Cunningham Littman')
      end
    end

    context 'when middle name is not provided' do
      let(:middle_name) { nil }

      it 'returns the correct fullname' do
        expect(fullname).to eq('Justin Littman')
      end
    end
  end

  describe '.construct_person' do
    subject(:person) do
      described_class.construct_person(id: id, given_name: given_name, middle_name: middle_name, family_name: family_name)
    end

    let(:given_name) { 'Justin' }

    let(:family_name) { 'Littman' }

    let(:id) { '123' }

    let(:middle_name) { 'Cunningham' }

    it 'returns the person' do
      expect(person).to eq(
        '@id' => Rialto::Etl::Vocabs::RIALTO_PEOPLE['123'],
        '@type' => [Rialto::Etl::Vocabs::FOAF['Agent'], Rialto::Etl::Vocabs::FOAF['Person']],
        Rialto::Etl::Vocabs::SKOS['prefLabel'].to_s => 'Justin Cunningham Littman',
        Rialto::Etl::Vocabs::RDFS['label'].to_s => 'Justin Cunningham Littman',
        Rialto::Etl::Vocabs::VCARD['hasName'].to_s => {
          '@id' => Rialto::Etl::Vocabs::RIALTO_CONTEXT_NAMES['123'],
          '@type' => Rialto::Etl::Vocabs::VCARD['Name'],
          "!#{Rialto::Etl::Vocabs::VCARD['given-name']}" => true,
          "!#{Rialto::Etl::Vocabs::VCARD['middle-name']}" => true,
          "!#{Rialto::Etl::Vocabs::VCARD['family-name']}" => true,
          Rialto::Etl::Vocabs::VCARD['given-name'].to_s => 'Justin',
          Rialto::Etl::Vocabs::VCARD['middle-name'].to_s => 'Cunningham',
          Rialto::Etl::Vocabs::VCARD['family-name'].to_s => 'Littman'

        }
      )
    end
  end
end
