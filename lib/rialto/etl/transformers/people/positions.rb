# frozen_string_literal: true

require 'rialto/etl/namespaces'

module Rialto
  module Etl
    module Transformers
      module People
        # Position transformer for the CAP Person API
        class Positions
          include Rialto::Etl::Vocabs

          # Transform titles from the CAP people api response to positions in the IR
          # @param titles [Array] a list of titles the person has
          # @param profile_id [String] the identifier for the person profile
          # @return [Array<Hash>] a list of vivo positions described in our IR
          def construct_positions(titles:, profile_id:)
            Array(titles).map do |title_json|
              org_code = title_json['organization']['orgCode']
              position_for(org_code: org_code,
                           hr_title: title_json['title'],
                           label: title_json['label']['text'],
                           profile_id: profile_id)
            end
          end

          private

          # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
          def position_for(org_code:, hr_title:, label:, profile_id:)
            {
              '@id' => RIALTO_CONTEXT_POSITIONS["#{org_code}_#{profile_id}"],
              '@type' => VIVO['Position'],
              "!#{DCTERMS['valid']}" => true,
              DCTERMS['valid'].to_s => Time.now.to_date,
              VIVO['relates'].to_s => [RIALTO_PEOPLE[profile_id], {
                '@id' => RIALTO_ORGANIZATIONS[orgs_map[org_code]],
                VIVO['relatedBy'].to_s => RIALTO_CONTEXT_POSITIONS["#{org_code}_#{profile_id}"]
              }],
              "!#{VIVO['hrJobTitle']}" => true,
              VIVO['hrJobTitle'].to_s => hr_title,
              "!#{RDFS['label']}" => true,
              RDFS['label'].to_s => label
            }
          end
          # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

          def orgs_map
            @orgs_map ||= Traject::TranslationMap.new('stanford_org_codes_to_organizations')
          end
        end
      end
    end
  end
end
