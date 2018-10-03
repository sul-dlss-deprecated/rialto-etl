# frozen_string_literal: true

require 'rialto/etl/namespaces'
require 'rialto/etl/logging'

module Rialto
  module Etl
    module Transformers
      module People
        # Address transformer
        class Addresses
          include Rialto::Etl::Vocabs
          include Rialto::Etl::Logging

          # Transform addresses into the hash for an address Vcard
          # @param id [String] an id to use to construct the Vcard URI
          # @param street_address [String] street address
          # @param locality [String] town / city
          # @param region [String] state
          # @param postal_code [String] zip
          # @param country [String] country
          # @return [Hash] a hash representing the Vcard
          # rubocop:disable Metrics/ParameterLists, Metrics/CyclomaticComplexity, Metrics/MethodLength
          def construct_address_vcard(id, street_address:, locality:, region:, postal_code:, country:)
            vcard = default_hash
            vcard['@id'] = RIALTO_CONTEXT_ADDRESSES[id]
            vcard[RDF::Vocab::VCARD['street-address'].to_s] = street_address if street_address
            vcard[RDF::Vocab::VCARD.locality.to_s] = locality if locality
            vcard[RDF::Vocab::VCARD.region.to_s] = region if region
            vcard[RDF::Vocab::VCARD['postal-code'].to_s] = postal_code if postal_code
            if country
              vcard[RDF::Vocab::VCARD['country-name'].to_s] = country
              if (geocode_id = geocode_id_for(country))
                vcard[RDF::Vocab::DC.spatial.to_s] = SWS_GEONAMES["#{geocode_id}/"]
              end
            end
            vcard
          end
          # rubocop:enable Metrics/ParameterLists, Metrics/CyclomaticComplexity, Metrics/MethodLength

          private

          def default_hash
            {
              '@type' => RDF::Vocab::VCARD.Address,
              "!#{RDF::Vocab::VCARD['street-address']}" => true,
              "!#{RDF::Vocab::VCARD.locality}" => true,
              "!#{RDF::Vocab::VCARD.region}" => true,
              "!#{RDF::Vocab::VCARD['country-name']}" => true,
              "!#{RDF::Vocab::VCARD['postal-code']}" => true,
              "!#{RDF::Vocab::DC.spatial}" => true
            }
          end

          def geocode_id_for(country)
            geocode_id = countries_map[country.downcase]
            logger.warn("Unmapped country: #{country}") unless geocode_id
            geocode_id
          end

          def countries_map
            @countries_map ||= [Traject::TranslationMap.new('country_names_to_geocode_ids'),
                                Traject::TranslationMap.new('additional_country_names_to_geocode_ids')].reduce(:merge)
          end
        end
      end
    end
  end
end
