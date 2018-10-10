# frozen_string_literal: true

require 'rialto/etl/transformers/people'
require 'rialto/etl/namespaces'

RSpec.describe Rialto::Etl::Transformers::People do
  before do
    Settings.entity_resolver.api_key = 'abc123'
    Settings.entity_resolver.url = 'http://127.0.0.1:3001'
    # Makes sure Entity Resolver is using above settings.
    Rialto::Etl::ServiceClient::EntityResolver.instance.initialize_connection
  end

  describe '.construct_stanford_positions' do
    subject(:positions) { described_class.construct_stanford_positions(titles: titles, profile_id: id) }

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
          .to eq RDF::URI('http://sul.stanford.edu/rialto/agents/orgs/school-of-medicine/deans-office/information-resources-and-technology-irt/it-services')
      end
    end

    context 'when titles are nil' do
      let(:titles) { nil }

      it 'returns positions' do
        expect(positions).to eq []
      end
    end

    context 'when org code is invalid' do
      let(:titles) do
        [{
          'label' => {
            'text' => 'UX Designer, SoM - Information Resources & Technology'
          },
          'organization' => {
            'orgCode' => 'XXXX'
          },
          'title' => 'UX Designer'
        }]
      end

      it 'returns positions' do
        expect(positions).to eq []
      end

      it 'logs a warning' do
        expect { positions.each {} }.to output(/Unmapped organization/).to_stderr
      end
    end
  end
  describe '.construct_position' do
    subject(:position) { described_class.construct_position(org_name: org_name, person_id: person_id) }

    let(:person_id) { '123' }

    let(:org_name) { 'Stanford University' }

    context 'when organization resolved' do
      before do
        stub_request(:get, 'http://127.0.0.1:3001/organization?name=Stanford%20University')
          .with(headers: { 'X-Api-Key' => 'abc123' })
          .to_return(status: 200, body: 'http://sul.stanford.edu/rialto/agents/orgs/stanford')
      end
      it 'returns position with resolved organization' do
        expect(position).to eq(
          '@id' => Rialto::Etl::Vocabs::RIALTO_CONTEXT_POSITIONS['stanford_123'],
          '@type' => Rialto::Etl::Vocabs::VIVO['Position'],
          Rialto::Etl::Vocabs::VIVO['relates'].to_s => [Rialto::Etl::Vocabs::RIALTO_PEOPLE['123'],
                                                        Rialto::Etl::Vocabs::RIALTO_ORGANIZATIONS['stanford']],
          '#position_person_relatedby' => {
            '@id' => Rialto::Etl::Vocabs::RIALTO_PEOPLE['123'],
            Rialto::Etl::Vocabs::VIVO['relatedBy'].to_s => Rialto::Etl::Vocabs::RIALTO_CONTEXT_POSITIONS['stanford_123']

          },
          '#position_org_relatedby' => {
            '@id' => Rialto::Etl::Vocabs::RIALTO_ORGANIZATIONS['stanford'],
            Rialto::Etl::Vocabs::VIVO['relatedBy'].to_s => Rialto::Etl::Vocabs::RIALTO_CONTEXT_POSITIONS['stanford_123']
          }
        )
      end
    end
    context 'when organization not resolved' do
      before do
        stub_request(:get, 'http://127.0.0.1:3001/organization?name=Stanford%20University')
          .with(headers: { 'X-Api-Key' => 'abc123' })
          .to_return(status: 404)
      end
      it 'returns position with new organization' do
        expect(position).to eq(
          '@id' => Rialto::Etl::Vocabs::RIALTO_CONTEXT_POSITIONS['0a4246f93dcdd2c0220c7cde1d23c989_123'],
          '@type' => Rialto::Etl::Vocabs::VIVO['Position'],
          Rialto::Etl::Vocabs::VIVO['relates'].to_s => [Rialto::Etl::Vocabs::RIALTO_PEOPLE['123'],
                                                        Rialto::Etl::Vocabs::RIALTO_ORGANIZATIONS['0a4246f93dcdd2c0220'\
                                                          'c7cde1d23c989']],
          '#position_person_relatedby' => {
            '@id' => Rialto::Etl::Vocabs::RIALTO_PEOPLE['123'],
            Rialto::Etl::Vocabs::VIVO['relatedBy'].to_s => Rialto::Etl::Vocabs::RIALTO_CONTEXT_POSITIONS['0a4246f93dcd'\
                                                          'd2c0220c7cde1d23c989_123']

          },
          '#position_org_relatedby' => {
            '@id' => Rialto::Etl::Vocabs::RIALTO_ORGANIZATIONS['0a4246f93dcdd2c0220c7cde1d23c989'],
            Rialto::Etl::Vocabs::VIVO['relatedBy'].to_s => Rialto::Etl::Vocabs::RIALTO_CONTEXT_POSITIONS['0a4246f93dcd'\
                                                          'd2c0220c7cde1d23c989_123']
          },
          '#organization' => {
            '@id' => Rialto::Etl::Vocabs::RIALTO_ORGANIZATIONS['0a4246f93dcdd2c0220c7cde1d23c989'],
            '@type' => [RDF::Vocab::FOAF.Agent, RDF::Vocab::FOAF.Organization],
            RDF::Vocab::SKOS.prefLabel.to_s => 'Stanford University',
            RDF::RDFS.label.to_s => 'Stanford University'
          }
        )
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
          '@type' => RDF::Vocab::VCARD['Name'],
          "!#{RDF::Vocab::VCARD['given-name']}" => true,
          "!#{RDF::Vocab::VCARD['additional-name']}" => true,
          "!#{RDF::Vocab::VCARD['family-name']}" => true,
          RDF::Vocab::VCARD['given-name'].to_s => 'Justin',
          RDF::Vocab::VCARD['additional-name'].to_s => 'Cunningham',
          RDF::Vocab::VCARD['family-name'].to_s => 'Littman'
        )
      end
      context 'when middle name and id not provided' do
        let(:middle_name) { nil }

        let(:id) { nil }

        it 'returns the correct fullname' do
          expect(vcard).to eq(
            '@id' => Rialto::Etl::Vocabs::RIALTO_CONTEXT_NAMES['ed1aa059391f675499eda6172ddc29f4'],
            '@type' => RDF::Vocab::VCARD['Name'],
            "!#{RDF::Vocab::VCARD['given-name']}" => true,
            "!#{RDF::Vocab::VCARD['additional-name']}" => true,
            "!#{RDF::Vocab::VCARD['family-name']}" => true,
            RDF::Vocab::VCARD['given-name'].to_s => 'Justin',
            RDF::Vocab::VCARD['family-name'].to_s => 'Littman'
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
        '@type' => [RDF::Vocab::FOAF.Agent, RDF::Vocab::FOAF.Person],
        RDF::Vocab::SKOS.prefLabel.to_s => 'Justin Cunningham Littman',
        RDF::Vocab::RDFS.label.to_s => 'Justin Cunningham Littman',
        RDF::Vocab::VCARD['hasName'].to_s => {
          '@id' => Rialto::Etl::Vocabs::RIALTO_CONTEXT_NAMES['123'],
          '@type' => RDF::Vocab::VCARD['Name'],
          "!#{RDF::Vocab::VCARD['given-name']}" => true,
          "!#{RDF::Vocab::VCARD['additional-name']}" => true,
          "!#{RDF::Vocab::VCARD['family-name']}" => true,
          RDF::Vocab::VCARD['given-name'].to_s => 'Justin',
          RDF::Vocab::VCARD['additional-name'].to_s => 'Cunningham',
          RDF::Vocab::VCARD['family-name'].to_s => 'Littman'

        }
      )
    end
  end
  describe '.resolve_or_construct_person' do
    subject(:person) do
      described_class.resolve_or_construct_person(given_name: given_name,
                                                  family_name: family_name,
                                                  addl_params: addl_params)
    end

    let(:given_name) { 'Justin' }

    let(:family_name) { 'Littman' }

    context 'when organization resolved' do
      let(:addl_params) { nil }

      before do
        stub_request(:get, 'http://127.0.0.1:3001/person?first_name=Justin&last_name=Littman')
          .with(headers: { 'X-Api-Key' => 'abc123' })
          .to_return(status: 200, body: 'http://sul.stanford.edu/rialto/agents/people/123')
      end
      it 'returns resolved person' do
        expect(person).to eq(
          '@id' => Rialto::Etl::Vocabs::RIALTO_PEOPLE['123']
        )
      end
    end
    context 'when person resolved' do
      let(:addl_params) { nil }

      before do
        stub_request(:get, 'http://127.0.0.1:3001/person?first_name=Justin&last_name=Littman')
          .with(headers: { 'X-Api-Key' => 'abc123' })
          .to_return(status: 404)
      end
      it 'returns unresolved person' do
        expect(person).to eq(
          '@id' => Rialto::Etl::Vocabs::RIALTO_PEOPLE['ed1aa059391f675499eda6172ddc29f4'],
          '@type' => [RDF::Vocab::FOAF.Agent, RDF::Vocab::FOAF.Person],
          RDF::Vocab::SKOS.prefLabel.to_s => 'Justin Littman',
          RDF::RDFS.label.to_s => 'Justin Littman',
          RDF::Vocab::VCARD.hasName.to_s => {
            '@id' => Rialto::Etl::Vocabs::RIALTO_CONTEXT_NAMES['ed1aa059391f675499eda6172ddc29f4'],
            '@type' => RDF::Vocab::VCARD.Name,
            "!#{RDF::Vocab::VCARD['given-name']}" => true,
            "!#{RDF::Vocab::VCARD['additional-name']}" => true,
            "!#{RDF::Vocab::VCARD['family-name']}" => true,
            RDF::Vocab::VCARD['given-name'].to_s => 'Justin',
            RDF::Vocab::VCARD['family-name'].to_s => 'Littman'
          }
        )
      end
    end
    context 'when additional parameters provided' do
      let(:addl_params) { { 'orcid_id' => '0000-0003-1527-0030' } }

      before do
        stub_request(:get, 'http://127.0.0.1:3001/person?first_name=Justin&last_name=Littman&orcid_id=0000-0003-1527-0030')
          .with(headers: { 'X-Api-Key' => 'abc123' })
          .to_return(status: 200, body: 'http://sul.stanford.edu/rialto/agents/people/123')
      end
      it 'returns resolved person' do
        expect(person).to eq(
          '@id' => Rialto::Etl::Vocabs::RIALTO_PEOPLE['123']
        )
      end
    end
  end
end
