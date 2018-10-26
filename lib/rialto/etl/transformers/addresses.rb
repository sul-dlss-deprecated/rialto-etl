# frozen_string_literal: true

require 'rialto/etl/transformers/addresses/countries'

module Rialto
  module Etl
    module Transformers
      # Transformers for addresses
      module Addresses
        # Constructs a country, including label.
        # @param country [String] name of the country
        # @return [Hash] Hash representing the country or nil
        def self.construct_country(country:)
          Rialto::Etl::Transformers::Addresses::Countries.new.construct_country(country: country)
        end
      end
    end
  end
end
