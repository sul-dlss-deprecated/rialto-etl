# frozen_string_literal: true

# frozen_string_literal: true

require 'traject'
require 'rdf'
require 'rdf/ntriples'

module Rialto
  module Etl
    module Loaders
      # Loader that takes Ntriples and puts it in SPARQL
      class Sparql
        # A valid file path
        attr_reader :input

        # Initialize a new instance of the loader
        #
        # @param input [String] valid file path of an Ntriples file
        def initialize(input:)
          @input = input
        end

        # Load a RDF file into a SPARQL endpoint, using Traject
        def load
          RDF::Reader.open(input) do |reader|
            loader.process(reader)
          end
        end

        private

        def loader
          @loader ||= Traject::Indexer.new.tap do |indexer|
            indexer.load_config_file('lib/rialto/etl/configs/sparql.rb')
          end
        end
      end
    end
  end
end
