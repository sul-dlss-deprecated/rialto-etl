# frozen_string_literal: true

require 'faraday'

module Rialto
  module Etl
    module ServiceClient
      # Builds Faraday connections with retry and long timeouts
      class OauthClientFactory
        attr_reader :client, :token

        def self.build(client_id:, client_secret:, token_url:)
          OAuth2::Client.new(client_id,
                             client_secret,
                             token_url: token_url,
                             auth_scheme: :request_body)
        end
      end
    end
  end
end
