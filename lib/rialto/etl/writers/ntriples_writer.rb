# frozen_string_literal: true

require 'rdf'
require 'traject'

module Rialto
  module Etl
    # Holds writers for use in Traject mappings
    module Writers
      # Write NTriples records
      class NtriplesWriter < Traject::LineWriter
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
          hash.each_pair do |field, values|
            Array(values).each do |value|
              graph << [subject, RDF::URI.new(field), value]
            end
          end
          graph.dump(:ntriples)
        end
      end
    end
  end
end
