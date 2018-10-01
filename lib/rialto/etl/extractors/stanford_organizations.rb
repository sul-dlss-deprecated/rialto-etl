# frozen_string_literal: true

require 'rialto/etl/logging'

module Rialto
  module Etl
    module Extractors
      # Stanford CAP API for orgs
      class StanfordOrganizations
        include Rialto::Etl::Logging

        def initialize(client: ServiceClient::StanfordClient.new)
          @client = client
        end

        # Hit an API endpoint and return the results
        def each(&_block)
          return to_enum(:each) unless block_given?
          yield client.get('/cap/v1/orgs/stanford?p=1&ps=10')
        rescue StandardError => exception
          logger.error("Error extracting Stanford organizations: #{exception.message}")
        end

        private

        attr_reader :client
      end
    end
  end
end
