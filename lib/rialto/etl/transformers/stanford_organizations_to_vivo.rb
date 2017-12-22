# frozen_string_literal: true

require 'traject_plus'
require 'rialto/etl/stanford_organizations_json_reader'

module Rialto
  module Etl
    module Transformers
      # Transformer turning Stanford org info into Vivo format
      class StanfordOrganizationsToVivo
        attr_reader :input

        def initialize(input:)
          @input = input
        end

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
