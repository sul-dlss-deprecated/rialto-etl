# frozen_string_literal: true

module Rialto
  module Etl
    module Extractors
      # Stanford Profiles API
      class StanfordResearchers
        def initialize(client: StanfordClient.new)
          @client = client
        end

        # Hit an API endpoint and return the results
        def extract
          per_page = 100 # 100 seems to be the max the API allows
          client.get("/profiles/v1?p=1&ps=#{per_page}")
        rescue StandardError => exception
          puts "Error: #{exception.message}"
        end

        private

        attr_reader :client
      end
    end
  end
end
