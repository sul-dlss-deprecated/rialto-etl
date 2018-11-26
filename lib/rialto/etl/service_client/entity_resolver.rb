# frozen_string_literal: true

require 'rdf'
require 'singleton'
require 'rialto/etl/logging'

module Rialto
  module Etl
    module ServiceClient
      # Client for hitting the RIALTO Entity Resolver
      class EntityResolver
        include Singleton
        include Rialto::Etl::Logging
        # @param type [String] the entity type to search for
        # @param params [Hash<String,String>] the entity attributes to search with
        def self.resolve(type, params)
          instance.resolve(type, params)
        end

        def initialize
          initialize_connection
        end

        attr_reader :conn

        def initialize_connection
          @conn = connection
        end

        # rubocop:disable Metrics/MethodLength
        def resolve(type, params)
          path = "#{type}?#{URI.encode_www_form(params)}"
          resp = conn.get(path)
          case resp.status
          when 200..299
            RDF::URI.new(resp.body)
          when 404
            nil
          else
            raise "Entity resolver returned #{resp.status} for #{type} type and #{params} params."
          end
        rescue StandardError => exception
          logger.error "Error resolving with path #{path}: #{exception.message}"
          raise
        end
        # rubocop:enable Metrics/MethodLength

        def connection
          RetriableConnectionFactory.build(uri: ::Settings.entity_resolver.url, headers: connection_headers)
        end

        def connection_headers
          key = Settings.entity_resolver.api_key
          { 'X-Api-Key' => key }
        end
      end
    end
  end
end
