# frozen_string_literal: true

require 'faraday'

module Rialto
  module Etl
    module ServiceClient
      # Builds Faraday connections with retry and long timeouts
      class OauthConnectionFactory
        def self.build(service_url:, client_id:, client_secret:, token_url:)
          client = OAuth2::Client.new(client_id,
                                      client_secret,
                                      token_url: token_url,
                                      auth_scheme: :request_body)
          token = client.client_credentials.get_token.token

          Faraday.new(service_url) do |connection|
            connection.request :oauth2, token, token_type: :bearer
            connection.adapter Faraday.default_adapter
          end
        end
      end
    end
  end
end
