# frozen_string_literal: true

module Rialto
  module Etl
    module ServiceClient
      # Client for hitting Stanford APIs using Stanford authz
      class WebOfScienceClient
        HOST = 'api.clarivate.com'
        PATH = '/api/wos'
        PARAMS = { 'databaseId' => 'WOK' }.freeze
        MAX_PER_PAGE = 100 # 100 is the max the API allows

        def initialize(firstname:, lastname:, institution:)
          @lastname = lastname
          @firstname = firstname
          @institution = institution
        end

        attr_reader :lastname, :firstname, :institution

        # @return [Faraday::Response] the response to the request
        def request(page: 1)
          connection.get(path(page: page))
        end

        # @return [Integer] the position of the last possible record on this page
        def last_record(page:)
          page * page_size
        end

        # @return [String] path for the query
        def path(page:)
          usr_query = "AU=#{lastname},#{firstname} AND OG=#{institution}"
          hash = PARAMS.merge(firstRecord: first_record(page: page), count: page_size, usrQuery: usr_query)
          uri = URI::HTTPS.build(host: HOST, path: PATH, query: URI.encode_www_form(hash))
          "#{uri.path}?#{uri.query}"
        end

        private

        def first_record(page:)
          1 + (page - 1) * page_size
        end

        def page_size
          MAX_PER_PAGE
        end

        def connection
          ConnectionFactory.build(uri: "https://#{HOST}", headers: connection_headers)
        end

        def connection_headers
          key = Settings.tokens.wos
          { 'X-ApiKey' => key }
        end
      end
    end
  end
end
