# frozen_string_literal: true

require 'rdf'
require 'traject'
require 'uuid'

module Rialto
  module Etl
    # Holds writers for use in Traject mappings
    module Writers
      # Write NTriples records
      class NtriplesWriter < Traject::LineWriter
        # rubocop:disable Metrics/AbcSize
        # rubocop:disable Metrics/MethodLength
        # rubocop:disable Metrics/LineLength
        # Overrides the serialization routine from superclass
        #
        # @param context [Traject::Indexer::Context] a Traject context
        #   object containing the output of the mapping
        # @return [String] NTriples representation of the mapping
        def serialize(context)
          hash = context.output_hash
          subject = RDF::URI.new(hash.delete('@id'))
          type = RDF::URI.new(hash.delete('@type'))
          graph = RDF::Graph.new << [subject, RDF.type, type]
          if hash.key?('@parent')
            parent = RDF::URI.new(hash.delete('@parent'))
            graph << [subject, RDF::URI.new('http://purl.obolibrary.org/obo/BFO_0000050'), RDF::URI.new(parent)]
          end
          if hash.key?('@webpage')
            webpage = RDF::Literal.new(hash.delete('@webpage'), datatype: RDF::XSD.anyURI)
            vcard_kind = RDF::URI.new("http://rialto.stanford.edu/cards/#{UUID.generate}")
            vcard_url = RDF::URI.new("http://rialto.stanford.edu/cards/#{UUID.generate}")
            graph << [subject, RDF::URI.new('http://purl.obolibrary.org/obo/ARG_2000028'), vcard_kind]
            graph << [vcard_kind, RDF.type, RDF::URI.new('http://www.w3.org/2006/vcard/ns#Kind')]
            graph << [vcard_kind, RDF.type, RDF::URI.new('http://www.w3.org/2006/vcard/ns#Individual')]
            graph << [vcard_kind, RDF::URI.new('http://purl.obolibrary.org/obo/ARG_2000029'), subject]
            graph << [vcard_kind, RDF::URI.new('http://www.w3.org/2006/vcard/ns#hasURL'), vcard_url]
            graph << [vcard_url, RDF.type, RDF::URI.new('http://www.w3.org/2006/vcard/ns#URL')]
            graph << [vcard_url, RDF::RDFS.label, 'Website']
            graph << [vcard_url, RDF::URI.new('http://vivoweb.org/ontology/core#rank'), RDF::Literal.new('1', datatype: RDF::XSD.int)]
            graph << [vcard_url, RDF::URI.new('http://www.w3.org/2006/vcard/ns#url'), webpage]
          end
          hash.each_pair do |field, values|
            Array(values).each do |value|
              graph << [subject, RDF::URI.new(field), value]
            end
          end
          graph.dump(:ntriples)
        end
        # rubocop:enable Metrics/AbcSize
        # rubocop:enable Metrics/MethodLength
        # rubocop:enable Metrics/LineLength
      end
    end
  end
end
