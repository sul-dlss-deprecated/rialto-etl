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
          # Returns the geocode id for a country name
          # @param country [String] name of the country
          # @return [RDF::Uri] Geonames URI for the country or nil
          def geocode_for_country(country:)
            geocode_id = countries_map[country.downcase]
            return Rialto::Etl::Vocabs::SWS_GEONAMES["#{geocode_id}/"] if geocode_id

            logger.warn("Unmapped country: #{country}") unless geocode_id
            nil
          end

          private

          def countries_map
            @countries_map ||= [Traject::TranslationMap.new('country_names_to_geocode_ids'),
                                Traject::TranslationMap.new('additional_country_names_to_geocode_ids')].reduce(:merge)
          end
        end
      end
    end
  end
end
