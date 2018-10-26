# frozen_string_literal: true

require 'rialto/etl/namespaces'
require 'rialto/etl/logging'

module Rialto
  module Etl
    module Transformers
      module Addresses
        # Country transformer
        class Countries
          include Rialto::Etl::Logging
          # Constructs a country, including label.
          # @param country [String] name of the country
          # @return [Hash] Hash representing the country or nil
          def construct_country(country:)
            geocode = geocode_for_country(country: country)
            return nil if geocode.nil?
            {
              '@id' => geocode,
              "!#{RDF::Vocab::RDFS.label}" => true,
              RDF::Vocab::RDFS.label.to_s => geocodes_map[geocode.to_s]
            }
          end

          private

          def geocode_for_country(country:)
            geocode_id = countries_map[country.downcase]
            return Rialto::Etl::Vocabs::SWS_GEONAMES["#{geocode_id}/"] if geocode_id

            logger.warn("Unmapped country: #{country}") unless geocode_id
            nil
          end

          def countries_map
            @countries_map ||= [Traject::TranslationMap.new('country_names_to_geocode_ids'),
                                Traject::TranslationMap.new('additional_country_names_to_geocode_ids')].reduce(:merge)
          end

          def geocodes_map
            @geocodes_map ||= Traject::TranslationMap.new('geocodes_to_country_names')
          end
        end
      end
    end
  end
end
