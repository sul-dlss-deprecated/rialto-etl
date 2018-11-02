# frozen_string_literal: true

require 'rdf'
require 'traject'
require 'sparql'
require 'sparql/client'
require 'rialto/etl/readers/sparql_statement_reader'
require 'rialto/etl/namespaces'

RSpec.describe Rialto::Etl::Transformer do
  let(:config_file_path) { 'lib/rialto/etl/configs/wos_to_sparql_statements.rb' }
  let(:graph) { Rialto::Etl::NamedGraphs::WOS_GRAPH }

  before do
    Settings.entity_resolver.api_key = 'abc123'
    Settings.entity_resolver.url = 'http://127.0.0.1:3001'
    # Makes sure Entity Resolver is using above settings.
    Rialto::Etl::ServiceClient::EntityResolver.instance.initialize_connection
  end

  describe 'wos_to_sparql_statements' do
    let(:repository) do
      RDF::Repository.new.tap do |repo|
        repo.insert(RDF::Statement.new(RDF::URI.new('foo'),
                                       RDF::URI.new('bar'),
                                       RDF::URI('foobar'),
                                       graph_name: Rialto::Etl::NamedGraphs::WOS_GRAPH))
      end
    end

    let(:client) do
      SPARQL::Client.new(repository)
    end

    before do
      stub_request(:get, 'http://127.0.0.1:3001/grant?identifier=LM05652')
        .with(headers: { 'X-Api-Key' => 'abc123' })
        .to_return(status: 200, body: 'http://sul.stanford.edu/rialto/grants/LM05652')

      stub_request(:get, 'http://127.0.0.1:3001/grant?identifier=GM61374')
        .with(headers: { 'X-Api-Key' => 'abc123' })
        .to_return(status: 200, body: 'http://sul.stanford.edu/rialto/grants/GM61374')

      stub_request(:get, 'http://127.0.0.1:3001/grant?identifier=U01FD004979')
        .with(headers: { 'X-Api-Key' => 'abc123' })
        .to_return(status: 200, body: 'http://sul.stanford.edu/rialto/grants/U01FD004979')

      stub_request(:get, 'http://127.0.0.1:3001/grant?identifier=GM102365')
        .with(headers: { 'X-Api-Key' => 'abc123' })
        .to_return(status: 200, body: 'http://sul.stanford.edu/rialto/grants/GM102365')
    end

    def transform(source_file)
      statements_io = StringIO.new

      transformer = Traject::Indexer.new.tap do |indexer|
        indexer.load_config_file(config_file_path)
        indexer.settings['output_stream'] = statements_io
      end

      # Converting fixture from pretty-printed JSON to single line.
      transformer.process(StringIO.new(File.open(source_file) { |file| file.read.delete("\n") }))
      statement_reader = Rialto::Etl::Readers::SparqlStatementReader.new(StringIO.new(statements_io.string),
                                                                         'sparql_statement_reader.by_statement' => true)
      statement_reader.each do |statement|
        SPARQL.execute(statement, repository, update: true)
      end
    end

    describe 'insert' do
      before do
        stub_request(:get, 'http://127.0.0.1:3001/person?country=Peoples%20R%20China&first_name=Jennifer%20L.&full_name=Wilson,%20Jennifer%20L.&last_name=Wilson&orcid_id=0000-0002-2328-2018&organization=Stanford%20University')
          .with(headers: { 'X-Api-Key' => 'abc123' })
          .to_return(status: 200, body: 'http://sul.stanford.edu/rialto/agents/people/15bf29be-470a-442e-9389-f66aac440a7b')

        stub_request(:get, 'http://127.0.0.1:3001/person?country=USA&first_name=Russ%20B.&full_name=Altman,%20Russ%20B.&last_name=Altman&organization=Stanford%20University')
          .with(headers: { 'X-Api-Key' => 'abc123' })
          .to_return(status: 200, body: 'http://sul.stanford.edu/rialto/agents/people/dc934b74-e554-409b-967b-0d555c44cc2c')

        stub_request(:get, 'http://127.0.0.1:3001/topic?name=Research%20%26%20Experimental%20Medicine')
          .with(headers: { 'X-Api-Key' => 'abc123' })
          .to_return(status: 200, body: 'http://sul.stanford.edu/rialto/concepts/d700824f-ae47-4244-885c-7cfc55b240f9')

        stub_request(:get, 'http://127.0.0.1:3001/organization?name=Stanford%20University')
          .with(headers: { 'X-Api-Key' => 'abc123' })
          .to_return(status: 200, body: 'http://sul.stanford.edu/rialto/agents/orgs/stanford')

        stub_request(:get, 'http://127.0.0.1:3001/organization?name=NIH')
          .with(headers: { 'X-Api-Key' => 'abc123' })
          .to_return(status: 200, body: 'http://sul.stanford.edu/rialto/agents/orgs/national_institutes_of_health')

        stub_request(:get, 'http://127.0.0.1:3001/organization?name=SAGE%20PUBLICATIONS%20LTD')
          .with(headers: { 'X-Api-Key' => 'abc123' })
          .to_return(status: 200, body: 'http://sul.stanford.edu/rialto/agents/orgs/sage_publications')

        transform('spec/fixtures/wos/000424386600014.json')
      end

      let(:id) { Rialto::Etl::Vocabs::RIALTO_PUBLICATIONS['1361324f8ff0b8ef1ed408a1f0b58107'] }
      let(:graph) { Rialto::Etl::NamedGraphs::WOS_GRAPH }

      it 'is inserted with publication triples' do
        # specific type
        expect(repository).to have_quad([id,
                                         RDF.type,
                                         RDF::Vocab::BIBO.Article,
                                         graph])
        # general type
        expect(repository).to have_quad([id,
                                         RDF.type,
                                         RDF::Vocab::BIBO.Document,
                                         graph])
        # has Part
        expect(repository).to have_quad([id,
                                         RDF::Vocab::DC.isPartOf,
                                         'EXPERIMENTAL BIOLOGY AND MEDICINE',
                                         graph])

        # Created
        expect(repository).to have_quad([id,
                                         RDF::Vocab::DC.created,
                                         RDF::Literal::Date.new('2018-02-01'),
                                         graph])

        # Subject
        expect(repository).to have_quad([id,
                                         RDF::Vocab::DC.subject,
                                         Rialto::Etl::Vocabs::RIALTO_CONCEPTS['d700824f-ae47-4244-885c-7cfc55b240f9'],
                                         graph])

        # Title
        expect(repository).to have_quad([id,
                                         RDF::Vocab::DC.title,
                                         'Biomarkers: Delivering on the expectation of molecularly driven, quantitative health',
                                         graph])

        # Abstract
        expect(repository).to have_quad([id,
                                         RDF::Vocab::BIBO.abstract,
                                         'Biomarkers are the pillars of precision medicine and are delivering on '\
                                         'expectations of molecular, quantitative health.',
                                         graph])
        # DOI
        expect(repository).to have_quad([id,
                                         RDF::Vocab::BIBO.doi,
                                         RDF::URI('http://dx.doi.org/10.1177/1535370217744775'),
                                         graph])
        # Identifier
        expect(repository).to has_quads([[id,
                                          RDF::Vocab::BIBO.identifier,
                                          '1535-3702',
                                          graph],
                                         [id,
                                          RDF::Vocab::BIBO.identifier,
                                          '1535-3699',
                                          graph],
                                         [id,
                                          RDF::Vocab::BIBO.identifier,
                                          '10.1177/1535370217744775',
                                          graph],
                                         [id,
                                          RDF::Vocab::BIBO.identifier,
                                          'MEDLINE:29199461',
                                          graph]])

        # Publisher
        expect(repository).to have_quad([id,
                                         Rialto::Etl::Vocabs::VIVO.publisher,
                                         Rialto::Etl::Vocabs::RIALTO_ORGANIZATIONS['sage_publications'],
                                         graph])

        # Authorships
        expect(repository).to has_quads(
          [[id,
            Rialto::Etl::Vocabs::VIVO.relatedBy,
            Rialto::Etl::Vocabs::RIALTO_CONTEXT_RELATIONSHIPS['WOS:000424386600014_15bf29be-470a-442e-9389-f66aac440a7b'],
            graph],
           [Rialto::Etl::Vocabs::RIALTO_CONTEXT_RELATIONSHIPS['WOS:000424386600014_15bf29be-470a-442e-9389-f66aac440a7b'],
            RDF.type,
            Rialto::Etl::Vocabs::VIVO.Authorship,
            graph],
           [Rialto::Etl::Vocabs::RIALTO_CONTEXT_RELATIONSHIPS['WOS:000424386600014_15bf29be-470a-442e-9389-f66aac440a7b'],
            Rialto::Etl::Vocabs::VIVO.relates,
            Rialto::Etl::Vocabs::RIALTO_PEOPLE['15bf29be-470a-442e-9389-f66aac440a7b'],
            graph]]
        )

        # Editorships
        expect(repository).to has_quads(
          [[id,
            Rialto::Etl::Vocabs::VIVO.relatedBy,
            Rialto::Etl::Vocabs::RIALTO_CONTEXT_RELATIONSHIPS['WOS:000424386600014_dc934b74-e554-409b-967b-0d555c44cc2c'],
            graph],
           [Rialto::Etl::Vocabs::RIALTO_CONTEXT_RELATIONSHIPS['WOS:000424386600014_dc934b74-e554-409b-967b-0d555c44cc2c'],
            RDF.type,
            Rialto::Etl::Vocabs::VIVO.Editorship,
            graph],
           [Rialto::Etl::Vocabs::RIALTO_CONTEXT_RELATIONSHIPS['WOS:000424386600014_dc934b74-e554-409b-967b-0d555c44cc2c'],
            Rialto::Etl::Vocabs::VIVO.relates,
            Rialto::Etl::Vocabs::RIALTO_PEOPLE['dc934b74-e554-409b-967b-0d555c44cc2c'],
            graph]]
        )

        # Supported by granting orgs
        expect(repository).to has_quads(
          [[id,
            Rialto::Etl::Vocabs::VIVO.informationResourceSupportedBy,
            Rialto::Etl::Vocabs::RIALTO_ORGANIZATIONS['national_institutes_of_health'],
            graph]]
        )

        # Has associated grants
        expect(repository).to has_quads(
          [
            [id,
             Rialto::Etl::Vocabs::VIVO.hasFundingVehicle,
             Rialto::Etl::Vocabs::RIALTO_GRANTS['LM05652'],
             graph],
            [id,
             Rialto::Etl::Vocabs::VIVO.hasFundingVehicle,
             Rialto::Etl::Vocabs::RIALTO_GRANTS['GM61374'],
             graph],
            [id,
             Rialto::Etl::Vocabs::VIVO.hasFundingVehicle,
             Rialto::Etl::Vocabs::RIALTO_GRANTS['U01FD004979'],
             graph],
            [id,
             Rialto::Etl::Vocabs::VIVO.hasFundingVehicle,
             Rialto::Etl::Vocabs::RIALTO_GRANTS['GM102365'],
             graph]
          ]
        )
      end
      it 'is inserted with author triples' do
        # Authors
        expect(repository).to has_quads(
          [[Rialto::Etl::Vocabs::RIALTO_PEOPLE['15bf29be-470a-442e-9389-f66aac440a7b'],
            RDF::Vocab::DC.spatial,
            Rialto::Etl::Vocabs::SWS_GEONAMES['1814991/'],
            graph]]
        )

        expect(repository).to has_quads(
          [[Rialto::Etl::Vocabs::RIALTO_PEOPLE['dc934b74-e554-409b-967b-0d555c44cc2c'],
            RDF::Vocab::DC.spatial,
            Rialto::Etl::Vocabs::SWS_GEONAMES['6252001/'],
            graph]]
        )

        # Authors are affiliated with orgs via positions
        expect(repository).to has_quads(
          [[Rialto::Etl::Vocabs::RIALTO_CONTEXT_POSITIONS['stanford_15bf29be-470a-442e-9389-f66aac440a7b'],
            RDF.type,
            Rialto::Etl::Vocabs::VIVO.Position,
            graph],
           [Rialto::Etl::Vocabs::RIALTO_CONTEXT_POSITIONS['stanford_15bf29be-470a-442e-9389-f66aac440a7b'],
            Rialto::Etl::Vocabs::VIVO.relates,
            Rialto::Etl::Vocabs::RIALTO_PEOPLE['15bf29be-470a-442e-9389-f66aac440a7b'],
            graph],
           [Rialto::Etl::Vocabs::RIALTO_CONTEXT_POSITIONS['stanford_15bf29be-470a-442e-9389-f66aac440a7b'],
            Rialto::Etl::Vocabs::VIVO.relates,
            Rialto::Etl::Vocabs::RIALTO_ORGANIZATIONS['stanford'],
            graph],
           [Rialto::Etl::Vocabs::RIALTO_PEOPLE['15bf29be-470a-442e-9389-f66aac440a7b'],
            Rialto::Etl::Vocabs::VIVO.relatedBy,
            Rialto::Etl::Vocabs::RIALTO_CONTEXT_POSITIONS['stanford_15bf29be-470a-442e-9389-f66aac440a7b'],
            graph],
           [Rialto::Etl::Vocabs::RIALTO_ORGANIZATIONS['stanford'],
            Rialto::Etl::Vocabs::VIVO.relatedBy,
            Rialto::Etl::Vocabs::RIALTO_CONTEXT_POSITIONS['stanford_15bf29be-470a-442e-9389-f66aac440a7b'],
            graph]]
        )
      end
    end
    describe 'create subjects, people, and organizations' do
      before do
        stub_request(:get, 'http://127.0.0.1:3001/person?country=Peoples%20R%20China&first_name=Jennifer%20L.&full_name=Wilson,%20Jennifer%20L.&last_name=Wilson&orcid_id=0000-0002-2328-2018&organization=Stanford%20University')
          .with(headers: { 'X-Api-Key' => 'abc123' })
          .to_return(status: 404)

        stub_request(:get, 'http://127.0.0.1:3001/person?country=USA&first_name=Russ%20B.&full_name=Altman,%20Russ%20B.&last_name=Altman&organization=Stanford%20University')
          .with(headers: { 'X-Api-Key' => 'abc123' })
          .to_return(status: 404)

        stub_request(:get, 'http://127.0.0.1:3001/topic?name=Research%20%26%20Experimental%20Medicine')
          .with(headers: { 'X-Api-Key' => 'abc123' })
          .to_return(status: 404)

        stub_request(:get, 'http://127.0.0.1:3001/organization?name=Stanford%20University')
          .with(headers: { 'X-Api-Key' => 'abc123' })
          .to_return(status: 404)

        stub_request(:get, 'http://127.0.0.1:3001/organization?name=NIH')
          .with(headers: { 'X-Api-Key' => 'abc123' })
          .to_return(status: 200, body: 'http://sul.stanford.edu/rialto/agents/orgs/national_institutes_of_health')

        stub_request(:get, 'http://127.0.0.1:3001/organization?name=SAGE%20PUBLICATIONS%20LTD')
          .with(headers: { 'X-Api-Key' => 'abc123' })
          .to_return(status: 200, body: 'http://sul.stanford.edu/rialto/agents/orgs/sage_publications')

        transform('spec/fixtures/wos/000424386600014.json')
      end

      let(:id) { Rialto::Etl::Vocabs::RIALTO_PUBLICATIONS['1361324f8ff0b8ef1ed408a1f0b58107'] }

      it 'is inserted with subject triples' do
        expect(repository).to have_quad([id,
                                         RDF::Vocab::DC.subject,
                                         Rialto::Etl::Vocabs::RIALTO_CONCEPTS['5a2cd5c7582ed1a1bbcc3a5c62786dca'],
                                         graph])

        expect(repository).to have_quad([Rialto::Etl::Vocabs::RIALTO_CONCEPTS['5a2cd5c7582ed1a1bbcc3a5c62786dca'],
                                         RDF.type,
                                         RDF::Vocab::SKOS.Concept,
                                         graph])

        expect(repository).to have_quad([Rialto::Etl::Vocabs::RIALTO_CONCEPTS['5a2cd5c7582ed1a1bbcc3a5c62786dca'],
                                         RDF::Vocab::DC.subject,
                                         'Research & Experimental Medicine',
                                         graph])
      end

      it 'is inserted with people triples' do
        expect(repository).to has_quads([[Rialto::Etl::Vocabs::RIALTO_PEOPLE['5054d6965532201e275067e4766c0ea0'],
                                          RDF.type,
                                          RDF::Vocab::FOAF.Person,
                                          graph],
                                         [Rialto::Etl::Vocabs::RIALTO_PEOPLE['5054d6965532201e275067e4766c0ea0'],
                                          RDF.type,
                                          RDF::Vocab::FOAF.Agent,
                                          graph]])
      end

      it 'is inserted with org triples' do
        expect(repository).to has_quads([[Rialto::Etl::Vocabs::RIALTO_ORGANIZATIONS['0a4246f93dcdd2c0220c7cde1d23c989'],
                                          RDF.type,
                                          RDF::Vocab::FOAF.Organization,
                                          graph],
                                         [Rialto::Etl::Vocabs::RIALTO_ORGANIZATIONS['0a4246f93dcdd2c0220c7cde1d23c989'],
                                          RDF.type,
                                          RDF::Vocab::FOAF.Agent,
                                          graph]])
      end
    end

    describe 'update publication' do
      before do
        stub_request(:get, 'http://127.0.0.1:3001/person?country=Peoples%20R%20China&first_name=Jennifer%20L.&full_name=Wilson,%20Jennifer%20L.&last_name=Wilson&orcid_id=0000-0002-2328-2018&organization=Stanford%20University')
          .with(headers: { 'X-Api-Key' => 'abc123' })
          .to_return(status: 200, body: 'http://sul.stanford.edu/rialto/agents/people/15bf29be-470a-442e-9389-f66aac440a7b')

        stub_request(:get, 'http://127.0.0.1:3001/person?country=USA&first_name=Russ%20B.&full_name=Altman,%20Russ%20B.&last_name=Altman&organization=Stanford%20University')
          .with(headers: { 'X-Api-Key' => 'abc123' })
          .to_return(status: 200, body: 'http://sul.stanford.edu/rialto/agents/people/dc934b74-e554-409b-967b-0d555c44cc2c')

        stub_request(:get, 'http://127.0.0.1:3001/person?country=USA&first_name=Justin%20C.&full_name=Littman,%20Justin%20C.&last_name=Littman&organization=Stanford%20University')
          .with(headers: { 'X-Api-Key' => 'abc123' })
          .to_return(status: 200, body: 'http://sul.stanford.edu/rialto/agents/people/dc934b74-e554-409b-967b-0d555c44cc2d')

        stub_request(:get, 'http://127.0.0.1:3001/topic?name=Research%20%26%20Experimental%20Medicine')
          .with(headers: { 'X-Api-Key' => 'abc123' })
          .to_return(status: 200, body: 'http://sul.stanford.edu/rialto/concepts/d700824f-ae47-4244-885c-7cfc55b240f9')

        stub_request(:get, 'http://127.0.0.1:3001/organization?name=Stanford%20University')
          .with(headers: { 'X-Api-Key' => 'abc123' })
          .to_return(status: 200, body: 'http://sul.stanford.edu/rialto/agents/orgs/stanford')

        stub_request(:get, 'http://127.0.0.1:3001/topic?name=Research%20%26%20Speculative%20Medicine')
          .with(headers: { 'X-Api-Key' => 'abc123' })
          .to_return(status: 200, body: 'http://sul.stanford.edu/rialto/concepts/d700824f-ae47-4244-885c-7cfc55b240f10')

        stub_request(:get, 'http://127.0.0.1:3001/organization?name=NIH')
          .with(headers: { 'X-Api-Key' => 'abc123' })
          .to_return(status: 200, body: 'http://sul.stanford.edu/rialto/agents/orgs/national_institutes_of_health')

        stub_request(:get, 'http://127.0.0.1:3001/organization?name=MONOPOLY%20PUBLICATIONS%20LTD')
          .with(headers: { 'X-Api-Key' => 'abc123' })
          .to_return(status: 200, body: 'http://sul.stanford.edu/rialto/agents/orgs/monopoly_publications')

        stub_request(:get, 'http://127.0.0.1:3001/organization?name=SAGE%20PUBLICATIONS%20LTD')
          .with(headers: { 'X-Api-Key' => 'abc123' })
          .to_return(status: 200, body: 'http://sul.stanford.edu/rialto/agents/orgs/sage_publications')

        transform('spec/fixtures/wos/000424386600014.json')
        transform('spec/fixtures/wos/000424386600014-2.json')
      end

      let(:id) { Rialto::Etl::Vocabs::RIALTO_PUBLICATIONS['1361324f8ff0b8ef1ed408a1f0b58107'] }

      it 'updates the publication' do
        # has Part
        expect(repository).to have_quad([id,
                                         RDF::Vocab::DC.isPartOf,
                                         'SPECULATIVE BIOLOGY AND MEDICINE',
                                         graph])
        expect(repository).not_to have_quad([id,
                                             RDF::Vocab::DC.isPartOf,
                                             'EXPERIMENTAL BIOLOGY AND MEDICINE',
                                             graph])

        # Created
        expect(repository).to have_quad([id,
                                         RDF::Vocab::DC.created,
                                         RDF::Literal::Date.new('2017-02-01'),
                                         graph])
        expect(repository).not_to have_quad([id,
                                             RDF::Vocab::DC.created,
                                             RDF::Literal::Date.new('2018-02-01'),
                                             graph])

        # Subject
        expect(repository).to have_quad([id,
                                         RDF::Vocab::DC.subject,
                                         Rialto::Etl::Vocabs::RIALTO_CONCEPTS['d700824f-ae47-4244-885c-7cfc55b240f10'],
                                         graph])
        expect(repository).not_to have_quad([id,
                                             RDF::Vocab::DC.subject,
                                             Rialto::Etl::Vocabs::RIALTO_CONCEPTS['d700824f-ae47-4244-885c-7cfc55b240f9'],
                                             graph])

        # Title
        expect(repository).to have_quad([id,
                                         RDF::Vocab::DC.title,
                                         'Biomarkers: Delivering some day on the expectation of molecularly driven, '\
                                         'quantitative health',
                                         graph])
        expect(repository).not_to have_quad([id,
                                             RDF::Vocab::DC.title,
                                             'Biomarkers: Delivering on the expectation of molecularly driven, quantitative health',
                                             graph])

        # Abstract
        expect(repository).to have_quad([id,
                                         RDF::Vocab::BIBO.abstract,
                                         'Biomarkers are the pillars of precision medicine and may some day deliver on '\
                                         'expectations of molecular, quantitative health.',
                                         graph])
        expect(repository).not_to have_quad([id,
                                             RDF::Vocab::BIBO.abstract,
                                             'Biomarkers are the pillars of precision medicine and are delivering on '\
                                             'expectations of molecular, quantitative health.',
                                             graph])
        # DOI
        expect(repository).to have_quad([id,
                                         RDF::Vocab::BIBO.doi,
                                         RDF::URI('http://dx.doi.org/10.1177/1535370217744774'),
                                         graph])
        expect(repository).not_to have_quad([id,
                                             RDF::Vocab::BIBO.doi,
                                             RDF::URI('http://dx.doi.org/10.1177/1535370217744775'),
                                             graph])
        # Identifier
        expect(repository).to has_quads([[id,
                                          RDF::Vocab::BIBO.identifier,
                                          '1535-3670',
                                          graph],
                                         [id,
                                          RDF::Vocab::BIBO.identifier,
                                          '10.1177/1535370217744774',
                                          graph],
                                         [id,
                                          RDF::Vocab::BIBO.identifier,
                                          'MEDLINE:29199461',
                                          graph]])
        expect(repository).not_to has_quads([[id,
                                              RDF::Vocab::BIBO.identifier,
                                              '1535-3702',
                                              graph],
                                             [id,
                                              RDF::Vocab::BIBO.identifier,
                                              '1535-3699']])

        # Publisher
        expect(repository).to have_quad([id,
                                         Rialto::Etl::Vocabs::VIVO.publisher,
                                         Rialto::Etl::Vocabs::RIALTO_ORGANIZATIONS['monopoly_publications'],
                                         graph])
        expect(repository).not_to have_quad([id,
                                             Rialto::Etl::Vocabs::VIVO.publisher,
                                             Rialto::Etl::Vocabs::RIALTO_ORGANIZATIONS['sage_publications'],
                                             graph])

        # Authorships
        expect(repository).to has_quads(
          [[Rialto::Etl::Vocabs::RIALTO_CONTEXT_RELATIONSHIPS['WOS:000424386600014_15bf29be-470a-442e-9389-f66aac440a7b'],
            Rialto::Etl::Vocabs::VIVO.relates,
            Rialto::Etl::Vocabs::RIALTO_PEOPLE['15bf29be-470a-442e-9389-f66aac440a7b'],
            graph],
           [Rialto::Etl::Vocabs::RIALTO_CONTEXT_RELATIONSHIPS['WOS:000424386600014_dc934b74-e554-409b-967b-0d555c44cc2d'],
            Rialto::Etl::Vocabs::VIVO.relates,
            Rialto::Etl::Vocabs::RIALTO_PEOPLE['dc934b74-e554-409b-967b-0d555c44cc2d'],
            graph]]
        )
        # Don't get rid of Authorship; just get rid of relationship between authorship and publication
        expect(repository).not_to have_quad([id,
                                             Rialto::Etl::Vocabs::VIVO.relatedBy,
                                             Rialto::Etl::Vocabs::RIALTO_CONTEXT_RELATIONSHIPS['WOS:000424386600014_'\
                                               'dc934b74-e554-409b-967b-0d555c44cc2c'],
                                             graph])
      end
    end
  end
  describe '#fetch_addresses' do
    subject { indexer.fetch_addresses(json) }

    let(:indexer) do
      Traject::Indexer.new.tap do |indexer|
        indexer.load_config_file(config_file_path)
      end
    end

    context 'with an address that does not have a pref label' do
      let(:json) do
        <<~JSON
          {
          	"UID": "WOS:000359895400001",
          	"static_data": {
          		"fullrecord_metadata": {
          			"addresses": {
          				"address_name": [{
          					"address_spec": {
          						"country": "USA",
          						"city": "Palo Alto",
          						"addr_no": 2,
          						"organizations": {
          							"organization": "Vet Adm Palo Alto",
          							"count": 1
          						},
          						"full_address": "Vet Adm Palo Alto, Palo Alto, CA USA",
          						"state": "CA"
          					}
          				}]
          			}
          		}
          	}
          }
        JSON
      end

      it { is_expected.to eq(2 => { 'country' => 'USA', 'organization' => 'Vet Adm Palo Alto' }) }
    end
    context 'with an address with a pref label' do
      let(:json) do
        <<~JSON2
          {
            "UID": "WOS:000359895400001",
            "static_data": {
              "fullrecord_metadata": {
                "addresses": {
                  "address_name": [{
                    "address_spec": {
                      "zip": {
          							"location": "AP",
          							"content": 94305
          						},
          						"country": "USA",
          						"city": "Stanford",
          						"addr_no": 1,
          						"organizations": {
          							"organization": ["Stanford Univ", {
          								"pref": "Y",
          								"content": "Stanford University"
          							}],
          							"count": 2
          						},
          						"full_address": "Stanford Univ, Stanford Cardiovasc Inst, Sch Med, Stanford, CA 94305 USA",
          						"state": "CA",
          						"suborganizations": {
          							"count": 2,
          							"suborganization": ["Stanford Cardiovasc Inst", "Sch Med"]
          						}
                    }
                  }]
                }
              }
            }
          }
        JSON2
      end

      it { is_expected.to eq(1 => { 'country' => 'USA', 'organization' => 'Stanford University' }) }
    end
    context 'with an address without organizations' do
      let(:json) do
        <<~JSON2
          {
            "UID": "WOS:000359895400001",
            "static_data": {
              "fullrecord_metadata": {
                "addresses": {
                  "address_name": [{
                    "address_spec": {
                      "zip": {
          							"location": "AP",
          							"content": 94305
          						},
          						"country": "USA",
          						"city": "Stanford",
          						"addr_no": 1,
          						"full_address": "Stanford Univ, Stanford Cardiovasc Inst, Sch Med, Stanford, CA 94305 USA",
          						"state": "CA",
          						"suborganizations": {
          							"count": 2,
          							"suborganization": ["Stanford Cardiovasc Inst", "Sch Med"]
          						}
                    }
                  }]
                }
              }
            }
          }
        JSON2
      end

      it { is_expected.to eq(1 => { 'country' => 'USA' }) }
    end
  end
  describe '#fetch_grant_agencies' do
    subject { indexer.fetch_grant_agencies(json) }

    let(:indexer) do
      Traject::Indexer.new.tap do |indexer|
        indexer.load_config_file(config_file_path)
      end
    end

    context 'with an array of grants' do
      let(:json) do
        <<~JSON
          {
          	"UID": "WOS:000359895400001",
          	"static_data": {
          		"fullrecord_metadata": {
                "fund_ack": {
                  "grants": {
                    "count": 3,
                    "grant": [{
                      "grant_ids": {
                        "grant_id": ["U01DK073983", "U01DK073975", "U01DK073985", "U01DK074007", "U01DK073974", "U01DK074008"],
                        "count": 6
                      },
                      "grant_agency": "National Institute of Diabetes and Digestive and Kidney Diseases"
                    }, {
                      "grant_ids": {
                        "grant_id": "DK57061",
                        "count": 1
                      },
                      "grant_agency": "National Institutes of Health"
                    }, {
                      "grant_ids": {
                        "grant_id": "PO1 DK68055",
                        "count": 1
                      },
                      "grant_agency": ""
                    }]
                  }
                }
          		}
          	}
          }
        JSON
      end

      it {
        is_expected.to eq(['National Institute of Diabetes and Digestive and Kidney Diseases',
                           'National Institutes of Health'])
      }
    end
    context 'with an grant obj' do
      let(:json) do
        <<~JSON
          {
          	"UID": "WOS:000359895400001",
          	"static_data": {
          		"fullrecord_metadata": {
                "fund_ack": {
                  "grants": {
                    "count": 3,
                    "grant": {
                      "grant_ids": {
                        "grant_id": ["U01DK073983", "U01DK073975", "U01DK073985", "U01DK074007", "U01DK073974", "U01DK074008"],
                        "count": 6
                      },
                      "grant_agency": "National Institute of Diabetes and Digestive and Kidney Diseases"
                    }
                  }
                }
          		}
          	}
          }
        JSON
      end

      it { is_expected.to eq(['National Institute of Diabetes and Digestive and Kidney Diseases']) }
    end
  end
  describe '#fetch_grant_identifiers' do
    subject { indexer.fetch_grant_identifiers(json) }

    let(:indexer) do
      Traject::Indexer.new.tap do |indexer|
        indexer.load_config_file(config_file_path)
      end
    end

    context 'with an string grant identifiers' do
      let(:json) do
        <<~JSON
          {
          	"UID": "WOS:000359895400001",
          	"static_data": {
          		"fullrecord_metadata": {
                "fund_ack": {
                  "grants": {
                    "count": 3,
                    "grant": [{
                      "grant_ids": {
                        "grant_id": ["U01DK073983", "U01DK073983"],
                        "count": 6
                      }
                    }, {
                      "grant_ids": {
                        "grant_id": "DK57061",
                        "count": 1
                      }
                    }, {
                      "grant_ids": {
                        "grant_id": "PO1 DK68055",
                        "count": 1
                      }
                    }]
                  }
                }
          		}
          	}
          }
        JSON
      end

      it {
        is_expected.to eq(['U01DK073983', 'U01DK073983', 'DK57061', 'PO1 DK68055'])
      }
    end
    context 'with an integer grant identifiers' do
      let(:json) do
        <<~JSON
          {
          	"UID": "WOS:000359895400001",
          	"static_data": {
          		"fullrecord_metadata": {
                "fund_ack": {
                  "grants": {
                    "count": 3,
                    "grant": [{
                      "grant_ids": {
                        "grant_id": [1019921, 1019922],
                        "count": 6
                      }
                    }, {
                      "grant_ids": {
                        "grant_id": 1019923,
                        "count": 1
                      }
                    }, {
                      "grant_ids": {
                        "grant_id": 1019924,
                        "count": 1
                      }
                    }]
                  }
                }
          		}
          	}
          }
        JSON
      end

      it {
        # rubocop:disable Style/WordArray
        is_expected.to eq(['1019921', '1019922', '1019923', '1019924'])
        # rubocop:enable Style/WordArray
      }
    end
  end
end
