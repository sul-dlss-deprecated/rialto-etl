# frozen_string_literal: true

require 'rialto/etl/writers/sparql_statement_writer'
require 'rialto/etl/readers/sparql_statement_reader'
require 'rdf'
require 'sparql'

RSpec.describe Rialto::Etl::Writers::SparqlStatementWriter do
  subject(:writer) { described_class.new({}) }

  let(:repository) do
    # Be aware: With default implementation of repository, named graphs are created by performing an insert
    # to the named graph. A delete to a named graph prior to that named graph being created will result in an
    # error.
    RDF::Repository.new
  end

  def execute_sparql(statements)
    statement_reader = Rialto::Etl::Readers::SparqlStatementReader.new(statements.flatten.join(";\n") + ";\n",
                                                                       'sparql_statement_reader.by_statement' => true)
    statement_reader.each do |statement|
      SPARQL.execute(statement, repository, update: true)
    end
  end

  describe '#graph_to_insert' do
    it 'produces insert data' do
      graph = RDF::Graph.new
      graph << [Rialto::Etl::Vocabs::RIALTO_PEOPLE['1234'], Rialto::Etl::Vocabs::SKOS['prefLabel'], 'Justin']
      execute_sparql([writer.graph_to_insert(graph, Rialto::Etl::NamedGraphs::STANFORD_PEOPLE_GRAPH)])
      expect(repository).to have_same_triples(graph)
    end
  end
  describe '#graph_to_delete' do
    it 'produces delete' do
      # First insert
      graph = RDF::Graph.new
      graph << [Rialto::Etl::Vocabs::RIALTO_PEOPLE['1234'], Rialto::Etl::Vocabs::SKOS['prefLabel'], 'Justin']
      execute_sparql([writer.graph_to_insert(graph, Rialto::Etl::NamedGraphs::STANFORD_PEOPLE_GRAPH)])
      expect(repository.size).to eq(1)

      # Then delete
      execute_sparql([writer.graph_to_delete(graph, Rialto::Etl::NamedGraphs::STANFORD_PEOPLE_GRAPH)])
      expect(repository.size).to eq(0)
    end
  end

  # rubocop:disable RSpec/MultipleExpectations
  describe '#values_to_delete_insert' do
    it 'produces insert data only when delete is false' do
      statements = writer.values_to_delete_insert(Rialto::Etl::Vocabs::RIALTO_PEOPLE['1234'],
                                                  [Rialto::Etl::Vocabs::SKOS['prefLabel'],
                                                   Rialto::Etl::Vocabs::FOAF['fn']],
                                                  ['Justin Littman', 'J. Littman'],
                                                  Rialto::Etl::NamedGraphs::STANFORD_PEOPLE_GRAPH)
      execute_sparql([statements])
      # noinspection RubyResolve
      expect(statements.first).to include('INSERT')
      # noinspection RubyResolve
      expect(statements.first).not_to include('DELETE')

      graph = RDF::Graph.new
      graph << [Rialto::Etl::Vocabs::RIALTO_PEOPLE['1234'], Rialto::Etl::Vocabs::SKOS['prefLabel'], 'Justin Littman']
      graph << [Rialto::Etl::Vocabs::RIALTO_PEOPLE['1234'], Rialto::Etl::Vocabs::SKOS['prefLabel'], 'J. Littman']
      graph << [Rialto::Etl::Vocabs::RIALTO_PEOPLE['1234'], Rialto::Etl::Vocabs::FOAF['fn'], 'Justin Littman']
      graph << [Rialto::Etl::Vocabs::RIALTO_PEOPLE['1234'], Rialto::Etl::Vocabs::FOAF['fn'], 'J. Littman']
      expect(repository).to have_same_triples(graph)
    end

    it 'produces delete and insert data when delete is true' do
      # First insert
      execute_sparql(writer.values_to_delete_insert(Rialto::Etl::Vocabs::RIALTO_PEOPLE['1234'],
                                                    Rialto::Etl::Vocabs::SKOS['prefLabel'],
                                                    'Justin Littman',
                                                    Rialto::Etl::NamedGraphs::STANFORD_PEOPLE_GRAPH))

      # Now delete insert
      statements = writer.values_to_delete_insert(Rialto::Etl::Vocabs::RIALTO_PEOPLE['1234'],
                                                  Rialto::Etl::Vocabs::SKOS['prefLabel'],
                                                  'J. Littman',
                                                  Rialto::Etl::NamedGraphs::STANFORD_PEOPLE_GRAPH,
                                                  true)
      execute_sparql([statements])
      expect(statements.length).to eq(2)
      # noinspection RubyResolve
      expect(statements.first).to include('DELETE')

      graph = RDF::Graph.new
      graph << [Rialto::Etl::Vocabs::RIALTO_PEOPLE['1234'], Rialto::Etl::Vocabs::SKOS['prefLabel'], 'J. Littman']
      expect(repository).to have_same_triples(graph)
    end
  end
  describe '#hash_to_delete_insert' do
    it 'produces delete and insert data' do
      # First insert
      hash = { Rialto::Etl::Vocabs::SKOS['prefLabel'].to_s => 'Justin Littman' }
      statements = writer.hash_to_delete_insert(Rialto::Etl::Vocabs::RIALTO_PEOPLE['1234'],
                                                hash,
                                                Rialto::Etl::NamedGraphs::STANFORD_PEOPLE_GRAPH).flatten
      execute_sparql([statements])
      expect(statements.length).to eq(1)
      # noinspection RubyResolve
      expect(statements.first).to include('INSERT')

      graph = RDF::Graph.new
      graph << [Rialto::Etl::Vocabs::RIALTO_PEOPLE['1234'], Rialto::Etl::Vocabs::SKOS['prefLabel'], 'Justin Littman']
      expect(repository).to have_same_triples(graph)

      # Then insert delete
      hash = { Rialto::Etl::Vocabs::SKOS['prefLabel'].to_s => 'J. Littman',
               '!' + Rialto::Etl::Vocabs::SKOS['prefLabel'].to_s => true }
      statements = writer.hash_to_delete_insert(Rialto::Etl::Vocabs::RIALTO_PEOPLE['1234'],
                                                hash,
                                                Rialto::Etl::NamedGraphs::STANFORD_PEOPLE_GRAPH).flatten
      execute_sparql([statements])
      expect(statements.length).to eq(2)
      # noinspection RubyResolve
      expect(statements.first).to include('DELETE')

      graph = RDF::Graph.new
      graph << [Rialto::Etl::Vocabs::RIALTO_PEOPLE['1234'], Rialto::Etl::Vocabs::SKOS['prefLabel'], 'J. Littman']
      expect(repository).to have_same_triples(graph)
    end

    it 'ignores @ and !' do
      hash = {
        '@foo' => 'bar',
        '!foo' => true
      }
      statements = writer.hash_to_delete_insert(Rialto::Etl::Vocabs::RIALTO_PEOPLE['1234'],
                                                hash,
                                                Rialto::Etl::NamedGraphs::STANFORD_PEOPLE_GRAPH).flatten
      expect(statements).to be_empty
    end
  end
  # rubocop:enable RSpec/MultipleExpectations
  describe '#hash_to_insert' do
    it 'produces insert data' do
      hash = { Rialto::Etl::Vocabs::SKOS['prefLabel'].to_s => 'Justin Littman' }
      statements = writer.hash_to_insert(Rialto::Etl::Vocabs::RIALTO_PEOPLE['1234'],
                                         hash,
                                         Rialto::Etl::NamedGraphs::STANFORD_PEOPLE_GRAPH)
      execute_sparql([statements])
      # noinspection RubyResolve
      expect(statements).to include('INSERT')

      graph = RDF::Graph.new
      graph << [Rialto::Etl::Vocabs::RIALTO_PEOPLE['1234'], Rialto::Etl::Vocabs::SKOS['prefLabel'], 'Justin Littman']
      expect(repository).to have_same_triples(graph)
    end

    it 'ignores @ and !' do
      hash = {
        '@foo' => 'bar',
        '!foo' => true
      }
      statements = writer.hash_to_insert(Rialto::Etl::Vocabs::RIALTO_PEOPLE['1234'],
                                         hash,
                                         Rialto::Etl::NamedGraphs::STANFORD_PEOPLE_GRAPH)
      expect(statements).to be_nil
    end
    describe '#serialize' do
      it 'handles @ and non-@ fields' do
        hash = {
          '@id' => '1234',
          '@id_ns' => Rialto::Etl::Vocabs::RIALTO_PEOPLE.to_s,
          '@graph' => Rialto::Etl::NamedGraphs::STANFORD_PEOPLE_GRAPH.to_s,
          '@type' => [Rialto::Etl::Vocabs::FOAF['person'], Rialto::Etl::Vocabs::VIVO['Librarian']],
          Rialto::Etl::Vocabs::VIVO['overview'].to_s => 'Justin Littman is a software developer and librarian.'
        }
        statements = writer.serialize_hash(hash)
        # Need to insert a statement so that named graph is created in local repository.
        statement = RDF::Statement.new(RDF::URI.new('foo'),
                                       RDF::URI.new('bar'),
                                       RDF::URI('foobar'),
                                       graph_name: Rialto::Etl::NamedGraphs::STANFORD_PEOPLE_GRAPH)
        repository.insert(statement)
        execute_sparql([statements])
        repository.delete(statement)

        graph = RDF::Graph.new
        graph << [Rialto::Etl::Vocabs::RIALTO_PEOPLE['1234'], RDF.type, Rialto::Etl::Vocabs::FOAF['person']]
        graph << [Rialto::Etl::Vocabs::RIALTO_PEOPLE['1234'], RDF.type, Rialto::Etl::Vocabs::VIVO['Librarian']]
        graph << [Rialto::Etl::Vocabs::RIALTO_PEOPLE['1234'],
                  Rialto::Etl::Vocabs::VIVO['overview'],
                  'Justin Littman is a software developer and librarian.']
        graph << [Rialto::Etl::Vocabs::RIALTO_PEOPLE['1234'],
                  Rialto::Etl::Vocabs::DCTERMS['valid'],
                  RDF::Literal::Date.new(Time.now.to_date)]
        expect(repository).to have_same_triples(graph)
      end
    end
  end
end
