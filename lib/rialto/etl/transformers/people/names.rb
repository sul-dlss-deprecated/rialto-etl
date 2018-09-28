# frozen_string_literal: true

require 'rialto/etl/namespaces'
require 'digest'

module Rialto
  module Etl
    module Transformers
      module People
        # Name transformer
        class Names
          include Rialto::Etl::Vocabs

          # Transform names into the hash for an address Vcard
          # @param id [String] an id to use to construct the Vcard URI. If omitted, one will be constructed.
          # @param given_name [String] first name
          # @param middle_name [String] middle name
          # @param family_name [String] last name
          # @return [Hash] a hash representing the Vcard
          def construct_name_vcard(id:, given_name:, middle_name: nil, family_name:)
            vcard = {
              '@id' => RIALTO_CONTEXT_NAMES[id || id_from_names(given_name, family_name)],
              '@type' => VCARD['Name'],
              "!#{VCARD['given-name']}" => true,
              VCARD['given-name'].to_s => given_name,
              "!#{VCARD['middle-name']}" => true,
              "!#{VCARD['family-name']}" => true,
              VCARD['family-name'].to_s => family_name
            }
            vcard[VCARD['middle-name'].to_s] = middle_name if middle_name
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
        end
      end
    end
  end
end
