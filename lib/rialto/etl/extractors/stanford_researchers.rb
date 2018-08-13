# frozen_string_literal: true

module Rialto
  module Etl
    module Extractors
      require 'byebug'
      # Stanford Profiles API
      class StanfordResearchers
        def initialize(client: StanfordClient.new)
          @client = client
        end

        # Hit an API endpoint and return the results
        def each(&_block)
          return to_enum(:each) unless block_given?
          per_page = 100 # 100 seems to be the max the API allows
          yield client.get("/profiles/v1?p=1&ps=#{per_page}")
        rescue StandardError => exception
          puts "Error: #{exception.message}"
        end

        private

        attr_reader :client
      end
    end
  end
end
