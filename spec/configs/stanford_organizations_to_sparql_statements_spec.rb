# frozen_string_literal: true

require 'traject'
require 'sparql'
require 'sparql/client'
require 'rialto/etl/readers/sparql_statement_reader'
require 'rialto/etl/namespaces'

STANFORD_ORGS_INSERT = <<~JSON
  {
  	"alias": "stanford",
  	"browsable": false,
  	"children": [{
  		"alias": "department-of-athletics-physical-education-and-recreation",
  		"browsable": false,
  		"children": [{
  			"alias": "department-of-athletics-physical-education-and-recreation/other-daper-administration",
  			"browsable": false,
  			"name": "Other DAPER Administration",
  			"onboarding": false,
  			"orgCodes": ["LAJE"],
  			"type": "DEPARTMENT"
  		}],
  		"name": "Physical Education and Recreation",
  		"onboarding": false,
  		"orgCodes": [
  			"LVTK",
  			"LVRC"
  		],
  		"type": "DEPARTMENT"
  	}],
  	"name": "Stanford University",
  	"onboarding": false,
  	"orgCodes": ["AA00"],
  	"type": "ROOT"
  }
JSON

STANFORD_ORGS_ADD_AND_DELETE = <<~JSON
  {
  	"alias": "stanford",
  	"browsable": false,
  	"children": [{
  		"alias": "department-of-athletics-physical-education-and-recreation",
  		"browsable": false,
  		"children": [{
			"alias": "department-of-athletics-physical-education-and-recreation/intercollegiate-sports",
			"browsable": false,
			"name": "Intercollegiate Sports",
			"onboarding": false,
			"orgCodes": ["LYIS", "LYBZ"],
			"type": "DIVISION"
		}],
  		"name": "Physical Education and Recreation",
  		"onboarding": false,
  		"orgCodes": [
  			"LVTK",
  			"LVRC"
  		],
  		"type": "DIVISION"
  	}],
  	"name": "Stanford University",
  	"onboarding": false,
  	"orgCodes": ["AA00"],
  	"type": "ROOT"
  }
JSON

STANFORD_ORGS_UPDATE = <<~JSON
  {
  	"alias": "amherst",
  	"browsable": false,
  	"children": [{
  		"alias": "department-of-athletics-physical-education-and-recreation",
  		"browsable": false,
  		"children": [{
  			"alias": "department-of-athletics-physical-education-and-recreation/other-daper-administration",
  			"browsable": false,
  			"name": "Other DAPER Administration",
  			"onboarding": false,
  			"orgCodes": ["LAJE"],
  			"type": "DEPARTMENT"
  		}],
  		"name": "Physical Education and Recreational Lounging",
  		"onboarding": false,
  		"orgCodes": [
  			"LVTK",
  			"LVRX"
  		],
  		"type": "DIVISION"
  	}],
  	"name": "Amherst College",
  	"onboarding": false,
  	"orgCodes": ["AA00"],
  	"type": "ROOT"
  }
JSON

RSpec.describe Rialto::Etl::Transformer do
  describe 'stanford_organizations_to_sparql_statements' do
    let(:repository) do
      RDF::Repository.new.tap do |repo|
        repo.insert(RDF::Statement.new(RDF::URI.new('foo'),
                                       RDF::URI.new('bar'),
                                       RDF::URI('foobar'),
                                       graph_name: Rialto::Etl::NamedGraphs::STANFORD_ORGANIZATIONS_GRAPH))
      end
    end

    let(:client) do
      SPARQL::Client.new(repository)
    end

    def transform(source)
      statements_io = StringIO.new

      transformer = Traject::Indexer.new.tap do |indexer|
        indexer.load_config_file('lib/rialto/etl/configs/stanford_organizations_to_sparql_statements.rb')
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
        transform(STANFORD_ORGS_INSERT)
      end
      # rubocop:disable RSpec/MultipleExpectations
      it 'is inserted with org triples' do
        # 3 organizations
        query = client.select(count: { org: :c })
                      .from(Rialto::Etl::NamedGraphs::STANFORD_ORGANIZATIONS_GRAPH)
                      .where([:org, RDF.type, Rialto::Etl::Vocabs::FOAF['Organization']])
                      .where([:org, RDF.type, Rialto::Etl::Vocabs::FOAF['Agent']])
        expect(query.solutions.first[:c].to_i).to eq(3)

        # Org URI correct
        result = client.ask
                       .from(Rialto::Etl::NamedGraphs::STANFORD_ORGANIZATIONS_GRAPH)
                       .whether([Rialto::Etl::Vocabs::RIALTO_ORGANIZATIONS['department-of-athletics-physical-'\
                          'education-and-recreation/other-daper-administration'], :p, :o])
                       .true?
        expect(result).to be true

        # Test label/name
        result = client.ask
                       .from(Rialto::Etl::NamedGraphs::STANFORD_ORGANIZATIONS_GRAPH)
                       .whether([Rialto::Etl::Vocabs::RIALTO_ORGANIZATIONS['department-of-athletics-physical-'\
                         'education-and-recreation/other-daper-administration'],
                                 Rialto::Etl::Vocabs::SKOS['prefLabel'],
                                 'Other DAPER Administration (Physical Education and Recreation)'])
                       .true?
        expect(result).to be true

        # Test parent
        result = client.ask
                       .from(Rialto::Etl::NamedGraphs::STANFORD_ORGANIZATIONS_GRAPH)
                       .whether([Rialto::Etl::Vocabs::RIALTO_ORGANIZATIONS['department-of-athletics-physical-'\
                          'education-and-recreation'],
                                 Rialto::Etl::Vocabs::OBO['BFO_0000050'],
                                 Rialto::Etl::Vocabs::RIALTO_ORGANIZATIONS['stanford']])
                       .true?
        expect(result).to be true

        # TODO: Test children

        # Test parent label/name
        result = client.ask
                       .from(Rialto::Etl::NamedGraphs::STANFORD_ORGANIZATIONS_GRAPH)
                       .whether([Rialto::Etl::Vocabs::RIALTO_ORGANIZATIONS['department-of-athletics-physical-'\
                          'education-and-recreation'],
                                 Rialto::Etl::Vocabs::SKOS['prefLabel'],
                                 'Physical Education and Recreation'])
                       .true?
        expect(result).to be true

        # Test org codes
        result = client.ask
                       .from(Rialto::Etl::NamedGraphs::STANFORD_ORGANIZATIONS_GRAPH)
                       .whether([Rialto::Etl::Vocabs::RIALTO_ORGANIZATIONS['department-of-athletics-physical-'\
                          'education-and-recreation'],
                                 Rialto::Etl::Vocabs::DCTERMS.identifier,
                                 'LVTK'])
                       .whether([Rialto::Etl::Vocabs::RIALTO_ORGANIZATIONS['department-of-athletics-physical-'\
                          'education-and-recreation'],
                                 Rialto::Etl::Vocabs::DCTERMS.identifier,
                                 'LVRC'])
                       .true?
        expect(result).to be true

        # Test org type
        result = client.ask
                       .from(Rialto::Etl::NamedGraphs::STANFORD_ORGANIZATIONS_GRAPH)
                       .whether([Rialto::Etl::Vocabs::RIALTO_ORGANIZATIONS['stanford'],
                                 RDF.type,
                                 Rialto::Etl::Vocabs::VIVO['University']])
                       .true?
        expect(result).to eq(true)
        result = client.ask
                       .from(Rialto::Etl::NamedGraphs::STANFORD_ORGANIZATIONS_GRAPH)
                       .whether([Rialto::Etl::Vocabs::RIALTO_ORGANIZATIONS['department-of-athletics-physical-'\
                          'education-and-recreation'],
                                 RDF.type,
                                 Rialto::Etl::Vocabs::VIVO['Department']])
                       .true?
        expect(result).to be true
      end

      # rubocop:enable RSpec/MultipleExpectations
    end

    describe 'add and delete orgs' do
      before do
        transform(STANFORD_ORGS_INSERT)
        transform(STANFORD_ORGS_ADD_AND_DELETE)
      end

      it 'adds the new org and leaves existing' do
        # 4 organizations
        query = client.select(count: { org: :c })
                      .from(Rialto::Etl::NamedGraphs::STANFORD_ORGANIZATIONS_GRAPH)
                      .where([:org, RDF.type, Rialto::Etl::Vocabs::FOAF['Organization']])
                      .where([:org, RDF.type, Rialto::Etl::Vocabs::FOAF['Agent']])
        expect(query.solutions.first[:c].to_i).to eq(4)
      end
    end

    describe 'update org' do
      before do
        transform(STANFORD_ORGS_INSERT)
        transform(STANFORD_ORGS_UPDATE)
      end
      # rubocop:disable RSpec/MultipleExpectations
      it 'updates the org' do
        # Changes org type
        result = client.ask
                       .from(Rialto::Etl::NamedGraphs::STANFORD_ORGANIZATIONS_GRAPH)
                       .whether([Rialto::Etl::Vocabs::RIALTO_ORGANIZATIONS['department-of-athletics-physical-'\
                          'education-and-recreation'],
                                 RDF.type,
                                 Rialto::Etl::Vocabs::VIVO['Department']])
                       .true?
        expect(result).to be false
        result = client.ask
                       .from(Rialto::Etl::NamedGraphs::STANFORD_ORGANIZATIONS_GRAPH)
                       .whether([Rialto::Etl::Vocabs::RIALTO_ORGANIZATIONS['department-of-athletics-physical-'\
                          'education-and-recreation'],
                                 RDF.type,
                                 Rialto::Etl::Vocabs::VIVO['Division']])
                       .true?
        expect(result).to be true

        # Changes label
        result = client.ask
                       .from(Rialto::Etl::NamedGraphs::STANFORD_ORGANIZATIONS_GRAPH)
                       .whether([Rialto::Etl::Vocabs::RIALTO_ORGANIZATIONS['department-of-athletics-physical-'\
                          'education-and-recreation'],
                                 Rialto::Etl::Vocabs::SKOS['prefLabel'],
                                 'Physical Education and Recreation'])
                       .true?
        expect(result).to be false
        result = client.ask
                       .from(Rialto::Etl::NamedGraphs::STANFORD_ORGANIZATIONS_GRAPH)
                       .whether([Rialto::Etl::Vocabs::RIALTO_ORGANIZATIONS['department-of-athletics-physical-'\
                          'education-and-recreation'],
                                 Rialto::Etl::Vocabs::SKOS['prefLabel'],
                                 'Physical Education and Recreational Lounging (Amherst College)'])
                       .true?
        expect(result).to be true

        # Changes org code
        result = client.ask
                       .from(Rialto::Etl::NamedGraphs::STANFORD_ORGANIZATIONS_GRAPH)
                       .whether([Rialto::Etl::Vocabs::RIALTO_ORGANIZATIONS['department-of-athletics-physical-education'\
                          '-and-recreation'],
                                 Rialto::Etl::Vocabs::DCTERMS.identifier,
                                 'LVTK'])
                       .whether([Rialto::Etl::Vocabs::RIALTO_ORGANIZATIONS['department-of-athletics-physical-'\
                          'education-and-recreation'],
                                 Rialto::Etl::Vocabs::DCTERMS.identifier,
                                 'LVRC'])
                       .true?
        expect(result).to be false
        result = client.ask
                       .from(Rialto::Etl::NamedGraphs::STANFORD_ORGANIZATIONS_GRAPH)
                       .whether([Rialto::Etl::Vocabs::RIALTO_ORGANIZATIONS['department-of-athletics-physical-'\
                          'education-and-recreation'],
                                 Rialto::Etl::Vocabs::DCTERMS.identifier,
                                 'LVTK'])
                       .whether([Rialto::Etl::Vocabs::RIALTO_ORGANIZATIONS['department-of-athletics-physical-'\
                          'education-and-recreation'],
                                 Rialto::Etl::Vocabs::DCTERMS.identifier,
                                 'LVRX'])
                       .true?
        expect(result).to be true

        # Changes parent
        result = client.ask
                       .from(Rialto::Etl::NamedGraphs::STANFORD_ORGANIZATIONS_GRAPH)
                       .whether([Rialto::Etl::Vocabs::RIALTO_ORGANIZATIONS['department-of-athletics-physical-'\
                          'education-and-recreation'],
                                 Rialto::Etl::Vocabs::OBO['BFO_0000050'],
                                 Rialto::Etl::Vocabs::RIALTO_ORGANIZATIONS['stanford']])
                       .true?
        expect(result).to be false
        result = client.ask
                       .from(Rialto::Etl::NamedGraphs::STANFORD_ORGANIZATIONS_GRAPH)
                       .whether([Rialto::Etl::Vocabs::RIALTO_ORGANIZATIONS['department-of-athletics-physical-'\
                          'education-and-recreation'],
                                 Rialto::Etl::Vocabs::OBO['BFO_0000050'],
                                 Rialto::Etl::Vocabs::RIALTO_ORGANIZATIONS['amherst']])
                       .true?
        expect(result).to be true

        # TODO: Test change children

        # rubocop:enable RSpec/MultipleExpectations
      end
    end
  end
end
