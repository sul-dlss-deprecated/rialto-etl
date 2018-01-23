# frozen_string_literal: true

require 'traject_plus'

module Rialto
  module Etl
    # Holds readers for use in Traject mappings
    module Readers
      # Read JSON that maps to Stanford orgs
      class StanfordOrganizationsJsonReader < TrajectPlus::JsonReader
        # Overrides the implementation inherited from superclass
        #
        # @param block [#call] a block that is executed on each organization
        # @return [String] JSON representation of an organization
        def each(&block)
          yield_children(hash: json, block: block)
        end

        private

        def yield_children(hash:, block:, parent: nil)
          hash['parent'] = parent if parent
          block.call(hash)
          children = children_path(hash)
          return if children.blank?
          children.each do |child|
            yield_children(hash: child, block: block, parent: hash['alias'])
          end
        end

        def children_path(hash)
          JsonPath.on(hash, '$.children').first
        end
      end
    end
  end
end
