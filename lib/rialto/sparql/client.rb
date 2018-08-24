# frozen_string_literal: true

require 'sparql/client'

module Rialto
  module SPARQL
    # Sends SPARQL queries to a remote server. This one supports X-Api-Key header
    class Client < ::SPARQL::Client
      # Set the API key header
      def pre_http_hook(request)
        key = Settings.tokens.rialto
        return unless key
        request.add_field('X-API-Key', key)
      end
    end
  end
end
