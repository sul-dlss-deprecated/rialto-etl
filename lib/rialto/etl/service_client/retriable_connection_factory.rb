# frozen_string_literal: true

require 'active_support/core_ext/class/attribute'
require 'faraday'

module Rialto
  module Etl
    module ServiceClient
      # Builds Faraday connections with retry and long timeouts
      class RetriableConnectionFactory
        MAX_RETRIES = 6

        class_attribute :logger

        # rubocop:disable Metrics/MethodLength
        def self.build(uri:, headers:, logger: default_logger)
          self.logger = logger

          Faraday.new(uri, headers: headers) do |connection|
            connection.request :retry, max: MAX_RETRIES,
                                       interval: 5.0,
                                       interval_randomness: 0.3,
                                       backoff_factor: 2.0,
                                       methods: retriable_methods, exceptions: retriable_exceptions, retry_block: retry_block,
                                       retry_statuses: retry_statuses

            connection.ssl.update(verify: true, verify_mode: OpenSSL::SSL::VERIFY_PEER)
            connection.adapter :net_http_persistent
            connection.options.timeout = 500
            connection.options.open_timeout = 10
          end
        end
        # rubocop:enable Metrics/MethodLength

        def self.retriable_methods
          Faraday::Request::Retry::IDEMPOTENT_METHODS + [:post]
        end
        private_class_method :retriable_methods

        def self.retriable_exceptions
          Faraday::Request::Retry::DEFAULT_EXCEPTIONS + [Faraday::ConnectionFailed]
        end
        private_class_method :retriable_exceptions

        def self.retry_block
          lambda { |env, _opts, retries, exception|
            logger.warn "retrying connection (#{retries} remaining) to #{env.url}: (#{exception.class}) #{exception.message}"
          }
        end
        private_class_method :retry_block

        def self.default_logger
          Yell.new(STDERR)
        end
        private_class_method :default_logger

        def self.retry_statuses
          [429]
        end
        private_class_method :retry_statuses
      end
    end
  end
end
