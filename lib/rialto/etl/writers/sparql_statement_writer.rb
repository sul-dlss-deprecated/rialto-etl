# frozen_string_literal: true

require 'rdf'
require 'traject'
require 'uuid'
require 'sparql/client'
require 'rialto/etl/namespaces'
require 'active_support/core_ext/array/wrap'

module Rialto
  module Etl
    # Holds writers for use in Traject mappings
    module Writers
      # Write Sparql statement records
      class SparqlStatementWriter < Traject::LineWriter
        extend Rialto::Etl::Vocabs
        # rubocop:disable Metrics/AbcSize
        # rubocop:disable Metrics/MethodLength
        # Overrides the serialization routine from superclass
        #
        # @param context [Traject::Indexer::Context] a Traject context
        #   object containing the output of the mapping
        # @return [String] Sparql representation of the mapping
        def serialize(context)
          # serialize_hash is a separate method to allow for recursion
          serialize_hash(context.output_hash).flatten.join(";\n") + ";\n"
        end

        # rubocop:disable Metrics/CyclomaticComplexity
        # rubocop:disable Metrics/PerceivedComplexity
        def serialize_hash(hash, graph_name = nil)
          statements = []
          subject = RDF::URI.new(hash['@id'])
          graph_name ||= hash['@graph']

          # Type
          statements << values_to_delete_insert(subject, RDF.type, hash['@type'], graph_name, true) if hash.key?('@type')

          hash.each do |field, value|
            # Ignore any @fields or !fields or #fields
            next if field.start_with?('@', '!', '#')
            # If value is not an array, make an array.
            values = Array.wrap(value)
            graph = RDF::Graph.new
            values.compact.each do |this_value|
              graph << if this_value.is_a?(Hash)
                         statements << serialize_hash(this_value, graph_name)
                         [subject, RDF::URI.new(field), RDF::URI.new(this_value['@id'])]
                       else
                         [subject, RDF::URI.new(field), this_value]
                       end
              # If !key, then delete.
              statements << graph_to_delete([[subject, RDF::URI.new(field), nil]], graph_name) if hash.key?('!' + field)
              statements << graph_to_insert(graph, graph_name) unless graph.empty?
            end
          end

          # Embedded output_hash
          hash.each do |field, value|
            next unless field.start_with?('#')
            values = Array.wrap(value)
            values.compact.each do |this_value|
              statements << serialize_hash(this_value, graph_name)
            end
          end

          statements
        end
        # rubocop:enable Metrics/CyclomaticComplexity
        # rubocop:enable Metrics/AbcSize
        # rubocop:enable Metrics/MethodLength

        def graph_to_insert(graph, graph_name)
          SPARQL::Client::Update::InsertData.new(graph, graph: graph_name).to_s.chomp
        end

        def graph_to_delete(graph, graph_name)
          # Note: Cannot perform insert in deleteinsert because insert is only performed when the where clause is
          # satisfied. Thus, it works for an update but not an initial insert.
          SPARQL::Client::Update::DeleteInsert.new(graph,
                                                   nil,
                                                   nil,
                                                   graph: graph_name).to_s.chomp
        end

        # rubocop:disable Metrics/MethodLength
        def values_to_delete_insert(subject, predicates, values, graph_name, delete = false)
          statements = []
          Array(predicates).each do |predicate|
            # Each delete needs to be a separate statement.
            statements << graph_to_delete([[subject, predicate, nil]], graph_name) if delete
          end
          graph = RDF::Graph.new
          Array(predicates).each do |predicate|
            Array(values).each do |value|
              graph << [subject, predicate, value]
            end
          end
          statements << graph_to_insert(graph, graph_name) unless graph.empty?
          statements
        end
        # rubocop:enable Metrics/MethodLength
        # rubocop:enable Metrics/PerceivedComplexity
      end
    end
  end
end
