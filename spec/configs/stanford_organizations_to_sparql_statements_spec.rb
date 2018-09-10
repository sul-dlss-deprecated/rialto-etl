# frozen_string_literal: true

require 'rdf'
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
  			"LVRC",
  			"LWGW",
  			"LVMR",
  			"LWAD"
  		],
  		"type": "DEPARTMENT"
  	}],
  	"name": "Stanford University",
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

    let(:statements_io) do
      StringIO.new
    end

    let(:transformer) do
      Traject::Indexer.new.tap do |indexer|
        indexer.load_config_file('lib/rialto/etl/configs/stanford_organizations_to_sparql_statements.rb')
        indexer.settings['output_stream'] = statements_io
      end
    end

    describe 'insert' do
      before do
        transformer.process(StringIO.new(STANFORD_ORGS_INSERT.delete("\n")))
        statement_reader = Rialto::Etl::Readers::SparqlStatementReader.new(StringIO.new(statements_io.string),
                                                                           'sparql_statement_reader.by_statement' => true)
        statement_reader.each do |statement|
          SPARQL.execute(statement, repository, update: true)
        end
      end

      it 'is inserted with org triples' do
        client = SPARQL::Client.new(repository)
        # 3 organizations
        query = client.select(count: { org: :c })
                      .from(Rialto::Etl::NamedGraphs::STANFORD_ORGANIZATIONS_GRAPH)
                      .where([:org, RDF.type, Rialto::Etl::Vocabs::FOAF.Organization])
        expect(query.solutions.first[:c].to_i).to eq(3)

        # TODO: More tests
      end
    end

    describe 'update' do
      # TODO
      it 'updates the org triples' do
        expect(repository.empty?).to eq(false)
      end
    end
  end
end
