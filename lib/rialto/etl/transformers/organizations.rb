# frozen_string_literal: true

require 'rialto/etl/namespaces'
require 'digest'

module Rialto
  module Etl
    module Transformers
      # Transformers for an Organization
      module Organizations
        # Transform name into the hash for an organization
        # @param org_name [String] the organization's name
        def self.construct_org(org_name:)
          {
            '@id' => Rialto::Etl::Vocabs::RIALTO_ORGANIZATIONS[Digest::MD5.hexdigest(org_name.downcase)],
            '@type' => [Rialto::Etl::Vocabs::FOAF['Agent'], Rialto::Etl::Vocabs::FOAF['Organization']],
            Rialto::Etl::Vocabs::SKOS['prefLabel'].to_s => org_name,
            Rialto::Etl::Vocabs::RDFS['label'].to_s => org_name
          }
        end

        # Resolves an organization otherwise transforms name into the hash for an organization
        # @param org_name [String] the organization's name
        def self.resolve_or_construct_org(org_name:)
          if (resolved_org = Rialto::Etl::ServiceClient::EntityResolver.resolve('organization', 'name' => org_name))
            {
              '@id' => resolved_org
            }
          else
            construct_org(org_name: org_name)
          end
        end
      end
    end
  end
end
