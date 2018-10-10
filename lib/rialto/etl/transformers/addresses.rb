# frozen_string_literal: true

require 'rialto/etl/transformers/addresses/countries'

module Rialto
  module Etl
    module Transformers
      # Transformers for addresses
      module Addresses
        # Returns the geocode id for a country name
        # @param country [String] name of the country
        # @return [RDF::Uri] Geonames URI for the country or nil
        def self.geocode_for_country(country:)
          Rialto::Etl::Transformers::Addresses::Countries.new.geocode_for_country(country: country)
        end
      end
    end
  end
end
