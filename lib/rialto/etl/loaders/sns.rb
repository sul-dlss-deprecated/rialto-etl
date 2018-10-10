# frozen_string_literal: true

require 'traject'

module Rialto
  module Etl
    module Loaders
      # Loader that takes SPARQL statements and posts SNS messages.
      class Sns
        # A valid file path
        attr_reader :input

        # Initialize a new instance of the loader
        #
        # @param input [String] valid file path of a SPARQL file
        def initialize(input:)
          @input = input
        end

        # Load SPARQL file into a SPARQL endpoint, using Traject
        def load
          File.open(input, 'r') do |stream|
            loader.process(stream)
          end
        end

        private

        def loader
          @loader ||= Traject::Indexer.new.tap do |indexer|
            indexer.load_config_file('lib/rialto/etl/configs/sns.rb')
          end
        end
      end
    end
  end
end
