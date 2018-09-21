# frozen_string_literal: true

require 'singleton'

module Rialto
  module Etl
    module ServiceClient
      # Client for hitting the RIALTO Entity Resolver
      class EntityResolver
        include Singleton

        # @param type [String] the entity type to search for
        # @param params [Hash<String,String>] the entity attributes to search with
        def self.resolve(type, params)
          instance.resolve(type, params)
        end

        def initialize
          @conn = connection
        end
        attr_reader :conn

        def resolve(type, params)
          resp = conn.get(type, params)
          case resp.status
          when 200..299
            RDF::URI.new(resp.body)
          when 404
            nil
          else
            raise "Entity resolver returned #{resp.status} for #{type} type and #{params} params."
          end
        end

        def connection
          ConnectionFactory.build(uri: ::Settings.entity_resolver.url, headers: connection_headers)
        end

        def connection_headers
          key = Settings.entity_resolver.api_key
          { 'X-Api-Key' => key }
        end
      end
    end
  end
end
