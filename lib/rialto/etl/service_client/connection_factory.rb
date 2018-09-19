# frozen_string_literal: true

require 'faraday'

module Rialto
  module Etl
    module ServiceClient
      # Builds Faraday connections with retry and long timeouts
      module ConnectionFactory
        def self.build(uri:, headers:)
          Faraday.new(uri, headers: headers) do |connection|
            connection.request :retry, max: 3, interval: 0.8, interval_randomness: 0.2, backoff_factor: 2
            connection.ssl.update(verify: true, verify_mode: OpenSSL::SSL::VERIFY_PEER)
            connection.adapter :net_http_persistent
            connection.options.timeout = 500
            connection.options.open_timeout = 10
          end
        end
      end
    end
  end
end
