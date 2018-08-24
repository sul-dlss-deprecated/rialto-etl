# frozen_string_literal: true

require 'rialto/etl/readers/ndjson_reader'
# require 'rdf'

module Rialto
  module Etl
    module Readers
      # Read newline-delimited JSON file, where each line is a json-LD object.
      # UTF-8 encoding is required.
      class NDJsonLDReader < NDJsonReader
        # @return [RDF::Graph]
        def decode(row, line_number)
          RDF::Graph.new << JSON::LD::API.toRdf(super)
        end
      end
    end
  end
end
