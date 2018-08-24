# frozen_string_literal: true

require 'traject'
require 'json/ld'

module Rialto
  module Etl
    module Loaders
      # Loader that takes newline delimited JSON, (with JSON-LD records) and puts it in SPARQL
      class Sparql
        # A valid file path
        attr_reader :input

        # Initialize a new instance of the loader
        #
        # @param input [String] valid file path of a newline delimited JSON-LD file
        def initialize(input:)
          @input = input
        end

        # Load a JSON-LD file into a SPARQL endpoint, using Traject
        def load
          File.open(input, 'r') do |stream|
            loader.process(stream)
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
