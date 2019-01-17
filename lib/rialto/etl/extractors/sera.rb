# frozen_string_literal: true

require 'faraday_middleware'
require 'oauth2'
require 'rialto/etl/logging'

module Rialto
  module Etl
    module Extractors
      # Documentation: https://asconfluence.stanford.edu/confluence/display/MaIS/SeRA+API+-+User+Documentation
      class Sera
        include Rialto::Etl::Logging

        def initialize(sunetid:)
          @sunetid = sunetid
        end

        # Hit an API endpoint and return the results
        def each(&_block)
          return to_enum(:each) unless block_given?
          body.each do |record|
            yield record.to_json
          end
        end

        private

        attr_reader :sunetid

        def client
          @client ||= begin
            oauth_client = OAuth2::Client.new(::Settings.sera.clientid,
                                              ::Settings.sera.secret,
                                              token_url: ::Settings.sera.token_url,
                                              auth_scheme: :request_body)

            ServiceClient::RetriableConnectionFactory.build(uri: ::Settings.sera.service_url,
                                                            headers: connection_headers,
                                                            oauth_token: oauth_client.client_credentials.get_token.token,
                                                            max_retries: ::Settings.sera.max_retries,
                                                            max_interval: ::Settings.sera.max_interval)
          end
        end

        # @return[Array<Hash>] the results of the API call
        # rubocop:disable Metrics/MethodLength
        def body
          case response.status
          when 404
            []
          when 400..499, 500..599
            raise "#{response.reason_phrase}: #{response.status}  (#{response.body})"
          else
            hash = JSON.parse(response.body)
            hash['SeRARecord']
          end
        rescue StandardError => exception
          logger.error "Error in extracting from SERA. #{exception.message} (#{exception.class})"
          raise
        end
        # rubocop:enable Metrics/MethodLength

        # @return [String] the path for the API request for the given sunetid
        def url
          "/mais/sera/v1/api?scope=sera.stanford-only&sunetId=#{sunetid}"
        end

        # @return [Faraday::Response]
        def response
          client.get(url)
        end

        def connection_headers
          {
            accept: 'application/json',
            content_type: 'application/json'
          }
        end
      end
    end
  end
end
