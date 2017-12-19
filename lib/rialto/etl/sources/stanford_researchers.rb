require 'faraday'
require 'openssl'
require 'base64'
require 'json'

module Rialto::Etl::Sources
  class StanfordResearchers
    attr_reader :access_token, :access_token_expiry_time

    def extract
      client.get("/profiles/v1?p=1&ps=10").body
    rescue => exception
      puts "Error: #{exception.message}"
    end

    private

      def client
        connection(uri: 'https://api.stanford.edu').tap do |conn|
          conn.headers['Authorization'] = access_token
        end
      end

      def connection(uri:)
        Faraday.new(uri, headers: connection_headers) do |connection|
          connection.request :retry,
                             max: 3,
                             interval: 0.8,
                             interval_randomness: 0.2,
                             backoff_factor: 2
          connection.ssl.update(verify: true, verify_mode: OpenSSL::SSL::VERIFY_PEER)
          connection.use Faraday::Response::RaiseError
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

      def reset_access_token!
        @access_token = nil
      end

      def token_expired?
        access_token_expiry_time < current_time
      rescue NoMethodError
        true
      end

      def reset_expiry_time!(expires_in:)
        @access_token_expiry_time = current_time + expires_in.to_i
      end

      def current_time
        Time.local(*Time.now).to_i
      end

      def auth_client
        @auth_client ||= connection(uri: 'https://authz.stanford.edu/oauth/token').tap do |conn|
          conn.headers['Authorization'] = "Basic #{auth_code}".freeze
        end
      end

      def auth_code
        @auth_code ||= Base64.strict_encode64("sul:#{ENV['CAP_TOKEN']}")
      end
  end
end
