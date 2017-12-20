# frozen_string_literal: true

require 'rialto/etl/extractors/abstract_stanford_extractor'

module Rialto
  module Etl
    module Extractors
      # Stanford Profiles API
      class StanfordResearchers < AbstractStanfordExtractor
        def extract
          client.get('/profiles/v1?p=1&ps=10').body
        rescue StandardError => exception
          puts "Error: #{exception.message}"
        end
      end
    end
  end
end
