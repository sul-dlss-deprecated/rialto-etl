# frozen_string_literal: true

require 'rialto/etl/sources/abstract_stanford_source'

module Rialto
  module Etl
    module Sources
      # Stanford CAP API for orgs
      class StanfordOrganizations < AbstractStanfordSource
        def extract
          client.get('/cap/v1/orgs/stanford?p=1&ps=10').body
        rescue StandardError => exception
          puts "Error: #{exception.message}"
        end
      end
    end
  end
end
