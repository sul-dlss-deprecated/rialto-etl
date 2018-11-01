# frozen_string_literal: true

module Rialto
  module Etl
    module Transformers
      # Transformers for identifiers
      module Identifiers
        ONLY_ALPHANUMERIC_CHARACTERS = /[^a-zA-Z0-9]/

        # Transform identifier into a normalized form
        # @param identifier [String] an identifier
        # @return [String] normalized form of given identifier
        def self.normalize(identifier:)
          identifier.downcase.gsub(ONLY_ALPHANUMERIC_CHARACTERS, '')
        end
      end
    end
  end
end
