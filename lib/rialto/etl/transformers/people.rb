# frozen_string_literal: true

require 'rialto/etl/transformers/people/positions'

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
      end
    end
  end
end
