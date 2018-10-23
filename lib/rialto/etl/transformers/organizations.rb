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
        # @param org_id [String] the ID, i.e., the URI less the namespace, of the organization (e.g.,
        #   department-of-athletics-physical-education-and-recreation/coed-sports)
        def self.construct_org(org_name:, org_id: nil)
          {
            '@id' => Rialto::Etl::Vocabs::RIALTO_ORGANIZATIONS[org_id || Digest::MD5.hexdigest(org_name.downcase)],
            '@type' => [RDF::Vocab::FOAF.Agent, RDF::Vocab::FOAF.Organization],
            RDF::Vocab::SKOS.prefLabel.to_s => org_name,
            RDF::RDFS.label.to_s => org_name
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
