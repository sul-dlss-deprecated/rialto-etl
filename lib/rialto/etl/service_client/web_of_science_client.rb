# frozen_string_literal: true

require 'rialto/etl/logging'

module Rialto
  module Etl
    module ServiceClient
      # Client for hitting Stanford APIs using Stanford authz
      class WebOfScienceClient
        include Rialto::Etl::Logging

        HOST = 'api.clarivate.com'
        USER_QUERY_PATH = '/api/wos'
        USER_QUERY_PARAMS = { 'databaseId' => 'WOS' }.freeze
        QUERY_BY_ID_PATH = '/api/wos/query'
        MAX_PER_PAGE = 100 # 100 is the max the API allows
        DEFAULT_QUERY_ID = 0
        NO_RECORDS_FOUND = 0

        def initialize(institution:, since: nil, publication_range: nil)
          @institution = institution
          @since = since
          @publication_range = publication_range
        end

        attr_reader :institution, :since, :publication_range

        # Hit the API endpoint and iterate over resulting records
        def each
          return to_enum(:each) unless block_given?

          publication_ranges.each do |pub_range|
            self.pub_range = pub_range

            # Run the initial query to get a query ID (for pagination)
            perform_initial_query!

            logger.info "records found: #{records_found}"

            first_record_values.each do |first_record|
              yield query_by_id(first_record: first_record)
            end
          end
        end

        private

        attr_accessor :records_found, :query_id, :pub_range

        def publication_ranges
          # Short-circuit publication ranges if `since` was supplied
          return Array.wrap(since) if since
          return Array.wrap(publication_range) if publication_range
          Settings.wos.publication_ranges
        end

        def query_by_id(first_record:)
          path = query_by_id_path(first_record: first_record)
          response = connect_with_retries(path: path)
          Array.wrap(response.dig('Records', 'records', 'REC'))
        end

        def perform_initial_query!
          response = connect_with_retries(path: user_query_path)
          @query_id = response.dig('QueryResult', 'QueryID') || DEFAULT_QUERY_ID
          @records_found = response.dig('QueryResult', 'RecordsFound') || NO_RECORDS_FOUND
        end

        def connect_with_retries(path:)
          logger.info "making request to #{path}"
          response = client.get(path)
          raise "#{response.reason_phrase}: #{response.status}  (#{response.body})" unless response.success?
          JSON.parse(response.body)
        rescue StandardError => exception
          logger.error "Error fetching #{path}: #{exception.message} (#{exception.class})"
          raise
        end

        # @return [String] path for the user query
        def user_query_path
          usr_query = "OG=#{institution}"
          params = USER_QUERY_PARAMS.merge(firstRecord: 1,
                                           count: 1,
                                           usrQuery: usr_query)
          if since
            params['loadTimeSpan'] = pub_range
          else
            params['publishTimeSpan'] = pub_range
          end
          build_uri(path: USER_QUERY_PATH, params: params)
        end

        # @return [String] path for the query with query ID
        def query_by_id_path(first_record:)
          params = { firstRecord: first_record, count: page_size }
          path = "#{QUERY_BY_ID_PATH}/#{query_id}"
          build_uri(path: path, params: params)
        end

        def build_uri(path:, params:)
          uri = URI::HTTPS.build(host: HOST, path: path, query: URI.encode_www_form(params))
          "#{uri.path}?#{uri.query}"
        end

        def first_record_values
          return [] if records_found.zero?
          0.upto(records_found / page_size).map do |value|
            value * page_size + 1
          end
        end

        def page_size
          MAX_PER_PAGE
        end

        def client
          RetriableConnectionFactory.build(uri: "https://#{HOST}",
                                           headers: connection_headers,
                                           max_retries: Settings.wos.max_retries,
                                           max_interval: Settings.wos.max_interval)
        end

        def connection_headers
          {
            'X-ApiKey' => Settings.wos.api_key
          }
        end
      end
    end
  end
end
