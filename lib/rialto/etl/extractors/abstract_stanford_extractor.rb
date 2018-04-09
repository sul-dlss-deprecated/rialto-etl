# frozen_string_literal: true

require 'faraday'
require 'openssl'
require 'base64'
require 'json'

module Rialto
  module Etl
    module Extractors
      # Abstract class hitting Stanford APIs using Stanford authz
      class AbstractStanfordExtractor
        # Time at which access token expires (as integer)
        attr_reader :access_token_expiry_time

        # Hit an API endpoint and return the results
        def extract
          raise NotImplementedError, 'Implement #extract in a child class'
        end

        private

        def client
          connection(uri: 'https://api.stanford.edu').tap do |conn|
            conn.headers['Authorization'] = access_token
          end
        end

        def connection(uri:)
          Faraday.new(uri, headers: connection_headers) do |connection|
            connection.request :retry, max: 3, interval: 0.8, interval_randomness: 0.2, backoff_factor: 2
            connection.ssl.update(verify: true, verify_mode: OpenSSL::SSL::VERIFY_PEER)
            connection.adapter :httpclient
            connection.options.timeout = 500
            connection.options.open_timeout = 10
          end
        end

        def connection_headers
          {
            accept: 'application/json',
            content_type: 'application/json'
          }
        end

        def access_token
          reset_access_token! if token_expired?
          @access_token ||= begin
                              response = auth_client.get '?grant_type=client_credentials'
                              raise 'Failed to authenticate' unless response.success?
                              auth_data = JSON.parse(response.body)
                              reset_expiry_time!(expires_in: auth_data['expires_in'])
                              "Bearer #{auth_data['access_token']}"
                            end
        end

        # Set the access token to `nil` to force retrieving a new one
        #
        # @return [void]
        def reset_access_token!
          @access_token = nil
        end

        def token_expired?
          access_token_expiry_time < current_time
        rescue NoMethodError
          true
        end

        # Set token expiry time to a new value based on current time
        #
        # @param expires_in [#to_i] time instance dictating when token expires
        # @return [void]
        def reset_expiry_time!(expires_in:)
          @access_token_expiry_time = current_time + expires_in.to_i
        end

        def current_time
          Time.local(*Time.now).to_i
        end

        def auth_client
          @auth_client ||= connection(uri: 'https://authz.stanford.edu/oauth/token').tap do |conn|
            conn.headers['Authorization'] = "Basic #{auth_code}"
          end
        end

        def auth_code
          @auth_code ||= Base64.strict_encode64("sul:#{Settings.tokens.cap}")
        end
      end
    end
  end
end
