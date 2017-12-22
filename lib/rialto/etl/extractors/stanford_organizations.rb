# frozen_string_literal: true

require 'rialto/etl/extractors/abstract_stanford_extractor'

module Rialto
  module Etl
    module Extractors
      # Stanford CAP API for orgs
      class StanfordOrganizations < AbstractStanfordExtractor
        # Hit an API endpoint and return the results
        def extract
          client.get('/cap/v1/orgs/stanford?p=1&ps=10').body
        rescue StandardError => exception
          puts "Error: #{exception.message}"
        end
      end
    end
  end
end
