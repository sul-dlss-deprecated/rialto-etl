# frozen_string_literal: true

require 'traject'

module Rialto
  module Etl
    module Transformers
      # Transformer turning Stanford org info into Vivo format
      class StanfordOrganizationsToVivo
        # A valid file path
        attr_reader :input

        # Initialize a new instance of the transformer
        #
        # @param [String] input valid file path
        def initialize(input:)
          @input = input
        end

        # Transform a stream into a new representation, using Traject
        def transform
          File.open(input, 'r') do |stream|
            transformer.process(stream)
          end
        end

        private

        def transformer
          @transformer ||= Traject::Indexer.new.tap do |indexer|
            indexer.load_config_file('lib/rialto/etl/configs/stanford_organizations.rb')
          end
        end
      end
    end
  end
end
