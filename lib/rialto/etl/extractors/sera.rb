# frozen_string_literal: true

require 'active_support/core_ext/class/attribute'
require 'faraday_middleware'
require 'oauth2'
require 'rialto/etl/logging'

module Rialto
  module Etl
    module Extractors
      # Documentation: https://asconfluence.stanford.edu/confluence/display/MaIS/SeRA+API+-+User+Documentation
      class Sera
        include Rialto::Etl::Logging
        class_attribute :oauth_client

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
          self.oauth_client ||= ServiceClient::OauthClientFactory.build(client_id: ::Settings.sera.clientid,
                                                                        client_secret: ::Settings.sera.secret,
                                                                        token_url: ::Settings.sera.token_url)

          @client || ServiceClient::RetriableConnectionFactory.build(uri: ::Settings.sera.service_url,
                                                                     oauth_token: oauth_client.client_credentials.get_token.token,
                                                                     max_retries: ::Settings.sera.max_retries,
                                                                     max_interval: ::Settings.sera.max_interval)
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
      end
    end
  end
end
