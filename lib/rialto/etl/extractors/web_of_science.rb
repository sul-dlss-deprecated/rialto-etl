# frozen_string_literal: true

require 'active_support/core_ext/array/wrap'

module Rialto
  module Etl
    module Extractors
      # Web of Science JSON API client
      class WebOfScience
        DEFAULT_INSTITUTION = 'Stanford University'

        attr_reader :client, :institution, :since

        # @param client [String] a preconfigured client. May be used for testing, all other options will be ignored.
        # @param institution [String] The institution to search for (default: 'Stanford University')
        # @param since [String] How far back to retrieve records. If not provided, extract all records. (default: nil)
        def initialize(client: nil, institution: DEFAULT_INSTITUTION, since: nil)
          @institution = institution
          @since = since
          # Must appear after other ivars because `#build_client` depends on the `#institution` and `#since` getters
          @client = client || build_client
        end

        # Use the client to iterate over records and yield them as JSON
        def each
          return to_enum(:each) unless block_given?
          client.each do |record|
            yield record.to_json
          end
        end

        private

        def build_client
          ServiceClient::WebOfScienceClient.new(
            institution: institution,
            since: since
          )
        end
      end
    end
  end
end
