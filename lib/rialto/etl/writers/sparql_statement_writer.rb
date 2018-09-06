# frozen_string_literal: true

require 'rdf'
require 'traject'
require 'uuid'
require 'sparql/client'
require 'rialto/etl/namespaces'

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
          hash = context.output_hash
          statements = []
          subject = RDF::URI.new(hash['@id_ns'] + hash['@id'].to_s)
          graph_name = hash['@graph']
          # Type
          statements << values_to_delete_insert(subject, RDF.type, hash['@type'], graph_name, hash.key?('!type'))

          # Label
          # SKOS.prefLabel & VCARD.fn
          statements << values_to_delete_insert(subject,
                                                [Vocabs::SKOS.prefLabel,
                                                 Vocabs::FOAF.fn], hash['@label'],
                                                graph_name,
                                                hash.key?('!label'))

          # Person name vcard
          statements << person_name_to_statements(subject, hash, graph_name) if hash.key?('@person_name')

          # Person address vcard
          statements << person_address_to_statements(subject, hash, graph_name) if hash.key?('@person_address')

          # All other
          statements << hash_to_delete_insert(subject, hash, graph_name)
          statements.flatten.join(";\n") + ";\n"
        end
        # rubocop:enable Metrics/AbcSize
        # rubocop:enable Metrics/MethodLength

        def graph_to_insert(graph, graph_name)
          SPARQL::Client::Update::InsertData.new(graph, graph: graph_name).to_s.chomp
        end

        def graph_to_delete(graph, graph_name)
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

        def hash_to_delete_insert(subject, hash, graph_name)
          statements = []
          hash.each_pair do |field, values|
            # Ignore any @fields or !fields
            next if field.start_with?('@', '!')
            statements << values_to_delete_insert(subject,
                                                  RDF::URI.new(field),
                                                  values,
                                                  graph_name,
                                                  hash.key?('!' + field))
          end
          statements
        end

        def hash_to_insert(subject, hash, graph_name, graph = nil)
          graph ||= RDF::Graph.new
          hash.each_pair do |field, values|
            # Ignore any @fields or !fields
            next if field.start_with?('@', '!')
            Array(values).each do |value|
              graph << [subject, RDF::URI.new(field), value]
            end
          end
          graph_to_insert(graph, graph_name) unless graph.empty?
        end


        # rubocop:disable Metrics/MethodLength
        def person_name_to_statements(subject, hash, graph_name)
          statements = []
          vcard = Vocabs::RIALTO_CONTEXT_NAMES[hash['@id']]
          if hash.key?('!person_name')
            statements << graph_to_delete([[subject,
                                            Vocabs::VCARD.hasName,
                                            nil]],
                                          graph_name)
            statements << graph_to_delete([[vcard, nil, nil]], graph_name)
          end
          graph = RDF::Graph.new
          graph << [subject, Vocabs::VCARD.hasName, vcard]
          graph << [vcard, RDF.type, Vocabs::VCARD.Name]
          statements << hash_to_insert(vcard,
                                       hash['@person_name'].first,
                                       graph_name,
                                       graph)
          statements
        end

        # rubocop:disable Metrics/MethodLength
        def person_address_to_statements(subject, hash, graph_name)
          statements = []
          vcard = Vocabs::RIALTO_CONTEXT_ADDRESSES[hash['@id']]
          if hash.key?('!person_address')
            statements << graph_to_delete([[subject,
                                            Vocabs::VCARD.hasAddress,
                                            nil]],
                                          graph_name)
            statements << graph_to_delete([[vcard, nil, nil]], graph_name)
          end
          graph = RDF::Graph.new
          graph << [subject, Vocabs::VCARD.hasAddress, vcard]
          graph << [vcard, RDF.type, Vocabs::VCARD.Address]
          statements << hash_to_insert(vcard,
                                       hash['@person_address'].first,
                                       graph_name, graph)
          statements
        end
        # rubocop:enable Metrics/MethodLength
        #
        # # Person address: if $.contacts.type == "academic":
        # #     Person Address URI: RIALTO Address NS (contexts) + $.contacts.address (Literal) + $.contacts.zip (Literal) (encode or replace spaces or other bad characters)
        # # Person VCARD.hasAddress Person Address URI .
        # #     Person Address URI RDF.type, VCARD.Address .
        # #         Person Address URI VCARD.street-address $.contacts.address (Literal)
        # # Person Address URI VCARD.locality $.contacts.city (Literal)
        # # Person Address URI VCARD.region $.contacts.state (Literal)
        # # Person Address URI VCARD.postal-code $.contacts.zip (Literal)
        # # Address URI DCTERMS.spatial country_uri (Geonames lookup based on $.contacts.zip)
        # # Address URI VCARD.country-name Name (Literal, from Geonames lookup based on $.contacts.zip)
      end
    end
  end
end
