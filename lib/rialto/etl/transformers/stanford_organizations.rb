# frozen_string_literal: true

module Rialto
  module Etl
    module Transformers
      # Transformer for Stanford orgs
      class StanfordOrganizations
        attr_reader :input

        def initialize(input:)
          @input = File.read(input)
        end

        def transform
          nil
        rescue StandardError => exception
          puts "Error: #{exception.message}"
        end
      end
    end
  end
end
