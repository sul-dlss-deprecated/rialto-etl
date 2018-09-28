# frozen_string_literal: true

require 'rialto/etl/transformers/people/positions'
require 'rialto/etl/transformers/people/addresses'
require 'rialto/etl/transformers/people/names'
require 'rialto/etl/namespaces'

module Rialto
  module Etl
    module Transformers
      # Transformers for a Person
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
        def self.construct_address_vcard(id, street_address: nil, locality: nil, region: nil, postal_code: nil, country: nil)
          Addresses.new.construct_address_vcard(id, street_address: street_address,
                                                    locality: locality,
                                                    region: region,
                                                    postal_code: postal_code,
                                                    country: country)
        end
        # rubocop:enable Metrics/ParameterLists

        # Transform names into the hash for a name Vcard
        # @param id [String] an id to use to construct the Vcard URI. If omitted, one will be constructed.
        # @param given_name [String] first name
        # @param middle_name [String] middle name
        # @param family_name [String] last name
        # @return [Hash] a hash representing the Vcard
        def self.construct_name_vcard(id: nil, given_name:, middle_name: nil, family_name:)
          Names.new.construct_name_vcard(id: id, given_name: given_name, middle_name: middle_name, family_name: family_name)
        end

        # Transform names into a full (concatenated) name
        # @param given_name [String] first name
        # @param middle_name [String] middle name
        # @param family_name [String] last name
        # @return [String] the full name
        def self.fullname_from_names(given_name:, middle_name: nil, family_name:)
          Names.new.fullname_from_names(given_name: given_name, middle_name: middle_name, family_name: family_name)
        end

        # Transform names into the hash for person, including types, labels, and name Vcard
        # @param id [String] an id to use to construct URIs. If omitted, one will be constructed.
        # @param given_name [String] first name
        # @param middle_name [String] middle name
        # @param family_name [String] last name
        # @return [Hash] a hash representing the person
        # rubocop:disable Metrics/MethodLength
        def self.construct_person(id: nil, given_name:, middle_name: nil, family_name:)
          names_constructor = Names.new
          id ||= names_constructor.id_from_names(given_name, family_name)
          full_name = names_constructor.fullname_from_names(given_name: given_name,
                                                            middle_name: middle_name,
                                                            family_name: family_name)
          {
            '@id' => Rialto::Etl::Vocabs::RIALTO_PEOPLE[id],
            '@type' => [Rialto::Etl::Vocabs::FOAF['Agent'], Rialto::Etl::Vocabs::FOAF['Person']],
            Rialto::Etl::Vocabs::SKOS['prefLabel'].to_s => full_name,
            Rialto::Etl::Vocabs::RDFS['label'].to_s => full_name,
            # Name VCard
            Rialto::Etl::Vocabs::VCARD['hasName'].to_s => names_constructor.construct_name_vcard(id: id,
                                                                                                 given_name: given_name,
                                                                                                 middle_name: middle_name,
                                                                                                 family_name: family_name)
          }
        end
        # rubocop:enable Metrics/MethodLength
      end
    end
  end
end
