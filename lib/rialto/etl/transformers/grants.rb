# frozen_string_literal: true

module Rialto
  module Etl
    module Transformers
      # Transformers for a Grant
      module Grants
        # @param grant_identifier [String] the grant's identifier
        # @return [Hash] the resolved grant
        def self.resolve_grant(grant_identifier:)
          resolved_grant = Rialto::Etl::ServiceClient::EntityResolver.resolve('grant', 'identifier' => grant_identifier)
          return if resolved_grant.nil?
          RDF::URI(resolved_grant)
        end
      end
    end
  end
end
