# frozen_string_literal: true

require 'rialto/etl/transformers/people/positions'
require 'rialto/etl/transformers/people/addresses'

module Rialto
  module Etl
    module Transformers
      # Transformers for the CAP Person API
      module People
        # Transform titles from the CAP people api response to positions in the IR
        # @param titles [Array] a list of titles the person has
        # @param profile_id [String] the identifier for the person profile
        # @return [Array<Hash>] a list of vivo positions described in our IR
        def self.construct_positions(titles:, profile_id:)
          Positions.new.construct_positions(titles: titles, profile_id: profile_id)
        end

        # Transform addresses into the hash for an address Vcard
        # @param id [String] an id to use to construct the Vcard URI
        # @param street_address [String] street address
        # @param locality [String] town / city
        # @param region [String] state
        # @param postal_code [String] zip
        # @param country [String] country
        # @return [Hash] a hash representing the Vcard
        # rubocop:disable Metrics/ParameterLists
        def self.construct_address(id, street_address: nil, locality: nil, region: nil, postal_code: nil, country: nil)
          Addresses.new.construct_address(id, street_address: street_address,
                                              locality: locality,
                                              region: region,
                                              postal_code: postal_code,
                                              country: country)
        end
        # rubocop:enable Metrics/ParameterLists
      end
    end
  end
end
