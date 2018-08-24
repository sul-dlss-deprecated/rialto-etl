# frozen_string_literal: true

require 'rdf'
require 'json/ld'
require 'traject'
require 'uuid'

module Rialto
  module Etl
    module Writers
      # Receives JSON-LD and writes Organization Ntriples records
      class OrganizationNtriplesWriter < Traject::LineWriter
        # Overrides the serialization routine from superclass
        #
        # @param context [Traject::Indexer::Context] a Traject context
        #   object containing the output of the mapping
        # @return [String] NTriples representation of the mapping
        def serialize(context)
          graph = RDF::Graph.new << JSON::LD::API.toRdf(context.output_hash)
          graph.dump(:ntriples)
        end
      end
    end
  end
end
