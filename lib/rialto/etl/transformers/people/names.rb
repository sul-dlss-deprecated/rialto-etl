# frozen_string_literal: true

require 'rialto/etl/namespaces'
require 'digest'
require 'set'

module Rialto
  module Etl
    module Transformers
      class People
        # Name transformer
        class Names
          # Transform names into the hash for an address Vcard
          # @param id [String] an id to use to construct the Vcard URI. If omitted, one will be constructed.
          # @param given_name [String] first name
          # @param middle_name [String] middle name
          # @param family_name [String] last name
          # @return [Hash] a hash representing the Vcard
          def construct_name_vcard(id:, given_name:, middle_name: nil, family_name:)
            vcard = {
              '@id' => Rialto::Etl::Vocabs::RIALTO_CONTEXT_NAMES[id || id_from_names(given_name, family_name)],
              '@type' => RDF::Vocab::VCARD.Name,
              "!#{RDF::Vocab::VCARD['given-name']}" => true,
              RDF::Vocab::VCARD['given-name'].to_s => given_name,
              "!#{RDF::Vocab::VCARD['additional-name']}" => true,
              "!#{RDF::Vocab::VCARD['family-name']}" => true,
              RDF::Vocab::VCARD['family-name'].to_s => family_name
            }
            vcard[RDF::Vocab::VCARD['additional-name'].to_s] = middle_name if middle_name
            vcard
          end

          # Constructs an id from a name.
          # @param given_name [String] first name
          # @param family_name [String] last name
          # @return [String] an id
          def id_from_names(given_name, family_name)
            Digest::MD5.hexdigest("#{given_name} #{family_name}".downcase)
          end

          # Constructs a full name from name parts.
          # @param given_name [String] first name
          # @param family_name [String] last name
          # @return [String] an id
          def fullname_from_names(given_name:, middle_name: nil, family_name:)
            name_parts = [given_name]
            name_parts << middle_name
            name_parts << family_name
            name_parts.compact.join(' ')
          end

          # Constructs name variations from name parts.
          # @param given_name [String] first name
          # @param family_name [String] last name
          # @return [Array(String)] array of name variations
          # rubocop:disable Metrics/MethodLength
          # rubocop:disable Metrics/AbcSize
          def name_variations_from_names(given_name:, middle_name: nil, family_name:)
            name_variations = Set.new
            # Check that a string because WoS sometimes return True
            return [] unless given_name&.is_a?(String)
            name_variations << "#{family_name}, #{given_name}"
            name_variations << "#{given_name} #{family_name}"
            given_initial = given_name[0]
            name_variations << "#{family_name}, #{given_initial}"
            name_variations << "#{family_name}, #{given_initial}."
            name_variations << "#{given_initial} #{family_name}"
            name_variations << "#{given_initial}. #{family_name}"

            if middle_name&.is_a?(String)
              name_variations << "#{family_name}, #{given_name} #{middle_name}"
              name_variations << "#{given_name} #{middle_name} #{family_name}"
              middle_initial = middle_name[0]
              name_variations << "#{family_name}, #{given_name} #{middle_initial}"
              name_variations << "#{family_name}, #{given_name} #{middle_initial}."
              name_variations << "#{given_name} #{middle_initial} #{family_name}"
              name_variations << "#{given_name} #{middle_initial}. #{family_name}"
              name_variations << "#{family_name}, #{given_initial}#{middle_initial}"
              name_variations << "#{family_name}, #{given_initial}.#{middle_initial}."
              name_variations << "#{given_initial}#{middle_initial} #{family_name}"
              name_variations << "#{given_initial}.#{middle_initial}. #{family_name}"
            end
            # Add downcased
            name_variations.merge(name_variations.map(&:downcase))
            name_variations.to_a
          end
          # rubocop:enable Metrics/MethodLength
          # rubocop:enable Metrics/AbcSize
        end
      end
    end
  end
end
