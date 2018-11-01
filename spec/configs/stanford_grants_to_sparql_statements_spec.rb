# frozen_string_literal: true

require 'traject'
require 'sparql'
require 'sparql/client'
require 'rialto/etl/readers/sparql_statement_reader'
require 'rialto/etl/namespaces'

STANFORD_GRANTS_INSERT1 = <<~JSON
  {
    "spoNumber": "12345-A",
    "projectTitle": "The Effects of Commas on Sentences",
    "projectStartDate": "2017-07-01T00:00:00.000-07:00",
    "projectEndDate": "2018-11-01T00:00:00.000-07:00",
    "directSponsorName": "The William and Flora Hewlett Foundation",
    "piFullName": "Giarlo, Michael J.",
    "piSunetId": "mjgiarlo"
  }
JSON

STANFORD_GRANTS_INSERT2 = <<~JSON
  {
    "spoNumber": "54321",
    "projectTitle": "Emoji as Cultural Signifiers",
    "projectStartDate": "2017-08-15T00:00:00.000-07:00",
    "projectEndDate": "2018-10-01T00:00:00.000-07:00",
    "directSponsorName": "The Foundation for Generous Funding",
    "piFullName": "Collier, Aaron M.",
    "piSunetId": "amcollie"
  }
JSON

STANFORD_GRANTS_ADD_AND_DELETE1 = <<~JSON
  {
    "spoNumber": "12345-A",
    "projectTitle": "The Effects of Commas on Sentences",
    "projectStartDate": "2017-07-01T00:00:00.000-07:00",
    "projectEndDate": "2018-11-01T00:00:00.000-07:00",
    "directSponsorName": "The William and Flora Hewlett Foundation",
    "piFullName": "Giarlo, Michael J.",
    "piSunetId": "mjgiarlo"
  }
JSON

STANFORD_GRANTS_ADD_AND_DELETE2 = <<~JSON
  {
    "spoNumber": "90210",
    "projectTitle": "Beverly Hills: Geographical Survey",
    "projectStartDate": "2017-07-15T00:00:00.000-07:00",
    "projectEndDate": "2018-12-01T00:00:00.000-07:00",
    "directSponsorName": "The Beverly M. F. Hills Society of Southern California",
    "piFullName": "Coyne, Justin M.",
    "piSunetId": "jcoyne85"
  }
JSON

STANFORD_GRANTS_UPDATE1 = <<~JSON
  {
    "spoNumber": "12345-A",
    "projectTitle": "The Effects of Commas on Sentences: Take Two",
    "projectStartDate": "2017-07-02T00:00:00.000-07:00",
    "projectEndDate": "2018-11-02T00:00:00.000-07:00",
    "directSponsorName": "The William & Flora Hewlett Foundation",
    "piFullName": "Giarlo, Michael J.",
    "piSunetId": "mjgiarlo"
  }
JSON

STANFORD_GRANTS_UPDATE2 = <<~JSON
  {
    "spoNumber": "54321",
    "projectTitle": "Emoji as Cultural Signifiers",
    "projectStartDate": "2017-08-15T00:00:00.000-07:00",
    "projectEndDate": "2018-10-01T00:00:00.000-07:00",
    "directSponsorName": "The Foundation for Generous Funding",
    "piFullName": "Collier, Aaron M.",
    "piSunetId": "amcollie"
  }
JSON

# rubocop:disable RSpec/DescribeClass
RSpec.describe 'stanford_grants_to_sparql_statements' do
  let(:repository) do
    RDF::Repository.new.tap do |repo|
      repo.insert(RDF::Statement.new(RDF::URI.new('foo'),
                                     RDF::URI.new('bar'),
                                     RDF::URI('foobar'),
                                     graph_name: Rialto::Etl::NamedGraphs::STANFORD_GRANTS_GRAPH))
    end
  end

  let(:client) do
    SPARQL::Client.new(repository)
  end

  let(:organization_uri) do
    RDF::URI('http://sul.stanford.edu/rialto/agents/orgs/the_william_and_flora_hewlett_foundation')
  end

  let(:updated_organization_uri) do
    RDF::URI('http://sul.stanford.edu/rialto/agents/orgs/the_william_flora_hewlett_foundation')
  end

  let(:mjgiarlo_uri) do
    RDF::URI('http://sul.stanford.edu/rialto/agents/people/71484')
  end

  let(:amcollie_uri) do
    RDF::URI('http://sul.stanford.edu/rialto/agents/people/182682')
  end

  let(:jcoyne_uri) do
    RDF::URI('http://sul.stanford.edu/rialto/agents/people/74784')
  end

  before do
    Settings.entity_resolver.api_key = 'abc123'
    Settings.entity_resolver.url = 'http://127.0.0.1:3001'
    # Makes sure Entity Resolver is using above settings.
    Rialto::Etl::ServiceClient::EntityResolver.instance.initialize_connection

    stub_request(:get, 'http://127.0.0.1:3001/organization?name=The%20William%20and%20Flora%20Hewlett%20Foundation')
      .to_return(status: 200,
                 body: organization_uri.to_s,
                 headers: {})

    stub_request(:get, 'http://127.0.0.1:3001/organization?name=The%20Foundation%20for%20Generous%20Funding')
      .to_return(status: 200,
                 body: 'http://sul.stanford.edu/rialto/agents/orgs/the_foundation_for_generous_funding',
                 headers: {})

    stub_request(:get, 'http://127.0.0.1:3001/organization?name=The%20Beverly%20M.%20F.%20Hills%20Society%20of%20Southern%20California')
      .to_return(status: 200,
                 body: 'http://sul.stanford.edu/rialto/agents/orgs/the_bev_hills_society',
                 headers: {})

    stub_request(:get, 'http://127.0.0.1:3001/organization?name=The%20William%20%26%20Flora%20Hewlett%20Foundation')
      .to_return(status: 200,
                 body: updated_organization_uri.to_s,
                 headers: {})

    stub_request(:get, 'http://127.0.0.1:3001/person?first_name=Michael%20J.&last_name=Giarlo&sunetid=mjgiarlo')
      .to_return(status: 200,
                 body: mjgiarlo_uri.to_s,
                 headers: {})

    stub_request(:get, 'http://127.0.0.1:3001/person?first_name=Aaron%20M.&last_name=Collier&sunetid=amcollie')
      .to_return(status: 200,
                 body: amcollie_uri.to_s,
                 headers: {})

    stub_request(:get, 'http://127.0.0.1:3001/person?first_name=Justin%20M.&last_name=Coyne&sunetid=jcoyne85')
      .to_return(status: 200,
                 body: jcoyne_uri.to_s,
                 headers: {})
  end

  def transform(source)
    statements_io = StringIO.new

    transformer = Traject::Indexer.new.tap do |indexer|
      indexer.load_config_file('lib/rialto/etl/configs/stanford_grants_to_sparql_statements.rb')
      indexer.settings['output_stream'] = statements_io
    end

    transformer.process(StringIO.new(source.delete("\n")))
    statement_reader = Rialto::Etl::Readers::SparqlStatementReader.new(StringIO.new(statements_io.string),
                                                                       'sparql_statement_reader.by_statement' => true)
    statement_reader.each do |statement|
      SPARQL.execute(statement, repository, update: true)
    end
  end

  describe 'insert' do
    before do
      transform(STANFORD_GRANTS_INSERT1)
      transform(STANFORD_GRANTS_INSERT2)
    end

    it 'inserts grant triples' do
      # 2 grants
      query = client.select(count: { grant: :c })
                    .from(Rialto::Etl::NamedGraphs::STANFORD_GRANTS_GRAPH)
                    .where([:grant, RDF.type, Rialto::Etl::Vocabs::VIVO.Grant])
      expect(query.solutions.first[:c].to_i).to eq(2)

      # Grant URI correct
      result = client.ask
                     .from(Rialto::Etl::NamedGraphs::STANFORD_GRANTS_GRAPH)
                     .whether([Rialto::Etl::Vocabs::RIALTO_GRANTS['12345-A'], :p, :o])
                     .true?
      expect(result).to be true

      # Test title
      result = client.ask
                     .from(Rialto::Etl::NamedGraphs::STANFORD_GRANTS_GRAPH)
                     .whether([Rialto::Etl::Vocabs::RIALTO_GRANTS['12345-A'],
                               RDF::Vocab::SKOS.prefLabel,
                               'The Effects of Commas on Sentences'])
                     .true?
      expect(result).to be true

      # Test bare identifier
      result = client.ask
                     .from(Rialto::Etl::NamedGraphs::STANFORD_GRANTS_GRAPH)
                     .whether([Rialto::Etl::Vocabs::RIALTO_GRANTS['12345-A'],
                               RDF::Vocab::DC.identifier,
                               '12345-A'])
                     .true?
      expect(result).to be true

      # Test normalized identifier
      result = client.ask
                     .from(Rialto::Etl::NamedGraphs::STANFORD_GRANTS_GRAPH)
                     .whether([Rialto::Etl::Vocabs::RIALTO_GRANTS['12345-A'],
                               RDF::Vocab::DC.identifier,
                               '12345a'])
                     .true?
      expect(result).to be true

      # Test start date
      result = client.ask
                     .from(Rialto::Etl::NamedGraphs::STANFORD_GRANTS_GRAPH)
                     .whether([Rialto::Etl::Vocabs::RIALTO_GRANTS['12345-A'],
                               Rialto::Etl::Vocabs::FRAPO.hasStartDate,
                               RDF::Literal::Date.new('2017-07-01')])
                     .true?
      expect(result).to be true

      # Test end date
      result = client.ask
                     .from(Rialto::Etl::NamedGraphs::STANFORD_GRANTS_GRAPH)
                     .whether([Rialto::Etl::Vocabs::RIALTO_GRANTS['12345-A'],
                               Rialto::Etl::Vocabs::FRAPO.hasEndDate,
                               RDF::Literal::Date.new('2018-11-01')])
                     .true?
      expect(result).to be true

      # Test grant sponsor URI
      result = client.ask
                     .from(Rialto::Etl::NamedGraphs::STANFORD_GRANTS_GRAPH)
                     .whether([Rialto::Etl::Vocabs::RIALTO_GRANTS['12345-A'],
                               Rialto::Etl::Vocabs::VIVO.assignedBy,
                               organization_uri])
                     .true?
      expect(result).to be true

      # Test grant relationship to PI (person)
      result = client.ask
                     .from(Rialto::Etl::NamedGraphs::STANFORD_GRANTS_GRAPH)
                     .whether([Rialto::Etl::Vocabs::RIALTO_GRANTS['12345-A'],
                               Rialto::Etl::Vocabs::VIVO.relates,
                               mjgiarlo_uri])
                     .true?
      expect(result).to be true
      result = client.ask
                     .from(Rialto::Etl::NamedGraphs::STANFORD_GRANTS_GRAPH)
                     .whether([mjgiarlo_uri,
                               Rialto::Etl::Vocabs::VIVO.relatedBy,
                               Rialto::Etl::Vocabs::RIALTO_GRANTS['12345-A']])
                     .true?
      expect(result).to be true
      result = client.ask
                     .from(Rialto::Etl::NamedGraphs::STANFORD_GRANTS_GRAPH)
                     .whether([mjgiarlo_uri,
                               Rialto::Etl::Vocabs::OBO.RO_0000053,
                               RDF::URI('http://sul.stanford.edu/rialto/context/roles/12345-A_mjgiarlo')])
                     .true?
      expect(result).to be true

      # Test grant relationship to PI (role)
      result = client.ask
                     .from(Rialto::Etl::NamedGraphs::STANFORD_GRANTS_GRAPH)
                     .whether([Rialto::Etl::Vocabs::RIALTO_GRANTS['12345-A'],
                               Rialto::Etl::Vocabs::VIVO.relates,
                               RDF::URI('http://sul.stanford.edu/rialto/context/roles/12345-A_mjgiarlo')])
                     .true?
      expect(result).to be true
      result = client.ask
                     .from(Rialto::Etl::NamedGraphs::STANFORD_GRANTS_GRAPH)
                     .whether([RDF::URI('http://sul.stanford.edu/rialto/context/roles/12345-A_mjgiarlo'),
                               Rialto::Etl::Vocabs::VIVO.relatedBy,
                               Rialto::Etl::Vocabs::RIALTO_GRANTS['12345-A']])
                     .true?
      expect(result).to be true
      result = client.ask
                     .from(Rialto::Etl::NamedGraphs::STANFORD_GRANTS_GRAPH)
                     .whether([RDF::URI('http://sul.stanford.edu/rialto/context/roles/12345-A_mjgiarlo'),
                               Rialto::Etl::Vocabs::OBO.RO_0000052,
                               mjgiarlo_uri])
                     .true?
      expect(result).to be true
      result = client.ask
                     .from(Rialto::Etl::NamedGraphs::STANFORD_GRANTS_GRAPH)
                     .whether([RDF::URI('http://sul.stanford.edu/rialto/context/roles/12345-A_mjgiarlo'),
                               RDF.type,
                               Rialto::Etl::Vocabs::VIVO.PrincipalInvestigatorRole])
                     .true?
      expect(result).to be true
    end
  end

  context 'when the dates are null' do
    let(:json) do
      <<~JSON
        {
          "spoNumber": "12345-A",
          "projectTitle": "The Effects of Commas on Sentences",
          "projectStartDate": null,
          "projectEndDate": null,
          "directSponsorName": "The William and Flora Hewlett Foundation",
          "piFullName": "Giarlo, Michael J.",
          "piSunetId": "mjgiarlo"
        }
      JSON
    end

    it 'transforms the record without errors' do
      expect { transform(json) }.not_to raise_error
    end
  end

  describe 'add and delete grants' do
    before do
      transform(STANFORD_GRANTS_INSERT1)
      transform(STANFORD_GRANTS_INSERT2)
      transform(STANFORD_GRANTS_ADD_AND_DELETE1)
      transform(STANFORD_GRANTS_ADD_AND_DELETE2)
    end

    it 'adds the new grant and leaves existing' do
      # 3 grants
      query = client.select(count: { grant: :c })
                    .from(Rialto::Etl::NamedGraphs::STANFORD_GRANTS_GRAPH)
                    .where([:grant, RDF.type, Rialto::Etl::Vocabs::VIVO.Grant])
      expect(query.solutions.first[:c].to_i).to eq(3)
    end
  end

  describe 'update grant' do
    before do
      transform(STANFORD_GRANTS_INSERT1)
      transform(STANFORD_GRANTS_INSERT2)
      transform(STANFORD_GRANTS_UPDATE1)
      transform(STANFORD_GRANTS_UPDATE2)
    end

    it 'updates the grant' do
      # Test title change
      result = client.ask
                     .from(Rialto::Etl::NamedGraphs::STANFORD_GRANTS_GRAPH)
                     .whether([Rialto::Etl::Vocabs::RIALTO_GRANTS['12345-A'],
                               RDF::Vocab::SKOS.prefLabel,
                               'The Effects of Commas on Sentences: Take Two'])
                     .true?
      expect(result).to be true

      # Test start date change
      result = client.ask
                     .from(Rialto::Etl::NamedGraphs::STANFORD_GRANTS_GRAPH)
                     .whether([Rialto::Etl::Vocabs::RIALTO_GRANTS['12345-A'],
                               Rialto::Etl::Vocabs::FRAPO.hasStartDate,
                               RDF::Literal::Date.new('2017-07-02')])
                     .true?
      expect(result).to be true

      # Test end date change
      result = client.ask
                     .from(Rialto::Etl::NamedGraphs::STANFORD_GRANTS_GRAPH)
                     .whether([Rialto::Etl::Vocabs::RIALTO_GRANTS['12345-A'],
                               Rialto::Etl::Vocabs::FRAPO.hasEndDate,
                               RDF::Literal::Date.new('2018-11-02')])
                     .true?
      expect(result).to be true

      # Test grant sponsor URI change
      result = client.ask
                     .from(Rialto::Etl::NamedGraphs::STANFORD_GRANTS_GRAPH)
                     .whether([Rialto::Etl::Vocabs::RIALTO_GRANTS['12345-A'],
                               Rialto::Etl::Vocabs::VIVO.assignedBy,
                               updated_organization_uri])
                     .true?
      expect(result).to be true
    end
  end
end
# rubocop:enable RSpec/DescribeClass
