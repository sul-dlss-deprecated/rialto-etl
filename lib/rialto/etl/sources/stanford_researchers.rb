# frozen_string_literal: true

require 'rialto/etl/sources/abstract_stanford_source'

module Rialto
  module Etl
    module Sources
      # Stanford Profiles API
      class StanfordResearchers < AbstractStanfordSource
        def extract
          client.get('/profiles/v1?p=1&ps=10').body
        rescue StandardError => exception
          puts "Error: #{exception.message}"
        end
      end
    end
  end
end
