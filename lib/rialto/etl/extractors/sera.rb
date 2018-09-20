# frozen_string_literal: true

require 'faraday_middleware'
require 'oauth2'

module Rialto
  module Etl
    module Extractors
      # Documetation: https://asconfluence.stanford.edu/confluence/display/MaIS/SeRA+API+-+User+Documentation
      class Sera
        def initialize(options = {})
          @sunetid = options.fetch(:sunetid)
        end

        # Hit an API endpoint and return the results
        def each(&_block)
          return to_enum(:each) unless block_given?
          body.each do |record|
            yield record.to_json
          end
        rescue StandardError => exception
          warn "Error: #{exception.message}"
        end

        private

        attr_reader :sunetid

        def client
          @client ||= Faraday.new ::Settings.sera.service_url do |conn|
            conn.request :oauth2, token, token_type: :bearer
            conn.adapter Faraday.default_adapter
          end
        end

        def token
          client = OAuth2::Client.new(::Settings.sera.clientid,
                                      ::Settings.sera.secret,
                                      token_url: ::Settings.sera.token_url,
                                      auth_scheme: :request_body)
          client.client_credentials.get_token.token
        end

        # @return[Array<Hash>] the results of the API call
        def body
          case response.status
          when 404
            []
          when 400..499, 500..599
            raise "There was a problem with the request to `#{url}` (#{response.status}): #{response.body}"
          else
            hash = JSON.parse(response.body)
            hash['SeRARecord']
          end
        end

        # @return [String] the path for the API request for the given sunetid
        def url
          "/mais/sera/v1/api?scope=sera.public&sunetId=#{sunetid}"
        end

        # @return [Faraday::Response]
        def response
          client.get(url)
        end
      end
    end
  end
end
