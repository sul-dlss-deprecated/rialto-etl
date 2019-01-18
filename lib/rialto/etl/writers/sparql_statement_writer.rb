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
        # Overrides the serialization routine from superclass
        #
        # @param context [Traject::Indexer::Context] a Traject context
        #   object containing the output of the mapping
        # @return [String] Sparql representation of the mapping
        def serialize(context)
          # serialize_hash is a separate method to allow for recursion
          serialize_hash(context.output_hash).flatten.join(";\n") + ";\n"
        end

        # rubocop:disable Metrics/MethodLength
        # rubocop:disable Metrics/AbcSize
        def serialize_hash(hash, graph_name = nil)
          statements = []
          subject = RDF::URI.new(hash['@id'])
          graph_name ||= hash['@graph']

          # @type
          statements << add_type_assertions(subject, hash['@type'], graph_name) if hash.key?('@type')

          hash.each do |field, value|
            # Ignore any @fields (because handled above) or !fields (because handled below)
            next if field.start_with?('@', '!')

            graph = RDF::Graph.new
            # If value is not an array, make an array and filter out nils
            values = Array.wrap(value).compact
            values.each do |this_value|
              # Skip to next iteration if #fields are handled. Do *not* run code
              #   below on #fields.
              next if handle_embedded_fields(field, statements, this_value, graph_name)

              graph << if this_value.is_a?(Hash)
                         statements << serialize_hash(this_value, graph_name)
                         [subject, RDF::URI.new(field), RDF::URI.new(this_value['@id'])]
                       else
                         [subject, RDF::URI.new(field), this_value]
                       end
            end
            statements << handle_delete_fields(subject, field, graph_name, hash)
            statements << graph_to_insert(graph, graph_name) if graph.any?
          end

          statements
        end
        # rubocop:enable Metrics/AbcSize
        # rubocop:enable Metrics/MethodLength

        def handle_embedded_fields(field, statements, value, graph_name)
          return unless field.start_with?('#')
          statements << serialize_hash(value, graph_name)
        end

        def handle_delete_fields(subject, field, graph_name, hash)
          # Do nothing if !key doesn't exist in hash, returning an
          #   empty array which is flattened/removed in #serialize. This moves
          #   some complexity from #serialize_hash into this smaller method.
          return [] unless hash.key?("!#{field}")
          graph_to_delete([[subject, RDF::URI.new(field), nil]], graph_name)
        end

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

        def add_type_assertions(subject, types, graph_name)
          statements = []
          statements << graph_to_delete([[subject, RDF.type, nil]], graph_name)
          graph = RDF::Graph.new
          Array(types).each do |type|
            graph << [subject, RDF.type, type]
          end
          statements << graph_to_insert(graph, graph_name) unless graph.empty?
          statements
        end
      end
    end
  end
end
