# frozen_string_literal: true

require 'rialto/etl/transformers/organizations'
require 'rialto/etl/namespaces'

RSpec.describe Rialto::Etl::Transformers::Organizations do
  before do
    Settings.entity_resolver.api_key = 'abc123'
    Settings.entity_resolver.url = 'http://127.0.0.1:3001'
    # Makes sure Entity Resolver is using above settings.
    Rialto::Etl::ServiceClient::EntityResolver.instance.initialize_connection
  end

  describe '.construct_organization' do
    subject(:org) do
      described_class.construct_org(org_name: org_name)
    end

    let(:org_name) { 'Stanford University' }

    it 'returns the organization' do
      expect(org).to eq(
        '@id' => Rialto::Etl::Vocabs::RIALTO_ORGANIZATIONS['0a4246f93dcdd2c0220c7cde1d23c989'],
        '@type' => [RDF::Vocab::FOAF.Agent, RDF::Vocab::FOAF.Organization],
        RDF::Vocab::SKOS.prefLabel.to_s => 'Stanford University',
        RDF::RDFS.label.to_s => 'Stanford University'
      )
    end
  end
  describe '.resolve_or_construct_organization' do
    subject(:org) { described_class.resolve_or_construct_org(org_name: org_name) }

    let(:org_name) { 'Stanford University' }

    context 'when organization resolved' do
      before do
        stub_request(:get, 'http://127.0.0.1:3001/organization?name=Stanford%20University')
          .with(headers: { 'X-Api-Key' => 'abc123' })
          .to_return(status: 200, body: 'http://sul.stanford.edu/rialto/agents/orgs/123')
      end
      it 'returns resolved org' do
        expect(org).to eq(
          '@id' => Rialto::Etl::Vocabs::RIALTO_ORGANIZATIONS['123']
        )
      end
    end
    context 'when organization resolved' do
      before do
        stub_request(:get, 'http://127.0.0.1:3001/organization?name=Stanford%20University')
          .with(headers: { 'X-Api-Key' => 'abc123' })
          .to_return(status: 404)
      end
      it 'returns unresolved organization' do
        expect(org).to eq(
          '@id' => Rialto::Etl::Vocabs::RIALTO_ORGANIZATIONS['0a4246f93dcdd2c0220c7cde1d23c989'],
          '@type' => [RDF::Vocab::FOAF.Agent, RDF::Vocab::FOAF.Organization],
          RDF::Vocab::SKOS.prefLabel.to_s => 'Stanford University',
          RDF::RDFS.label.to_s => 'Stanford University'
        )
      end
    end
  end
end
