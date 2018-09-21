# frozen_string_literal: true

module SparqlHelper
  require 'rialto/etl/readers/sparql_statement_reader'
  require 'sparql'

  def execute_sparql!(statements)
    # Need to insert a statement so that named graph is created in local repository.
    repository.insert(named_graph_setup_statement)

    statement_reader = Rialto::Etl::Readers::SparqlStatementReader.new(format_statements(statements),
                                                                       'sparql_statement_reader.by_statement' => true)
    statement_reader.each do |statement|
      SPARQL.execute(statement, repository, update: true)
    end

    # And now delete the setup statement
    repository.delete(named_graph_setup_statement)
  end

  private

  def format_statements(statements)
    Array(statements).flatten.join(";\n") + ";\n"
  end

  def named_graph_setup_statement
    RDF::Statement.new(RDF::URI.new('foo'),
                       RDF::URI.new('bar'),
                       RDF::URI('foobar'),
                       graph_name: Rialto::Etl::NamedGraphs::STANFORD_PEOPLE_GRAPH)
  end
end
