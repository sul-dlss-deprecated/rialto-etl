# frozen_string_literal: true

module Rialto
  module Etl
    # Holds writers for use in Traject mappings
    module Writers
      # Write JSON-LD representing Stanford orgs. This writer conforms
      # to Traject's writer class interface, supporting #initialize,
      # #put, and #close
      class StanfordOrganizationsJsonldWriter
        # No-op
        def initialize(_); end

        # Append the hash representing a single mapped record to the
        # list of records held in memory
        def put(context)
          records << context.output_hash
        end

        # Pretty-print a JSON representation of the records with the
        # JSON-LD context object attached
        def close
          $stdout.puts JSON.pretty_generate(build_object)
        end

        private

        def records
          @records ||= []
        end

        def build_object
          {
            '@context' => {
              # @todo not yet used. will be used to model parent/child rels
              # obo: 'http://purl.obolibrary.org/obo/',
              rdfs: 'http://www.w3.org/2000/01/rdf-schema#',
              vivo: 'http://vivoweb.org/ontology/core#'
            },
            '@graph' => records
          }
        end
      end
    end
  end
end
