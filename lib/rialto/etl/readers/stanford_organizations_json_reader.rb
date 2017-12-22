# frozen_string_literal: true

module Rialto
  module Etl
    # Holds readers for use in Traject mappings
    module Readers
      # Read JSON that maps to Stanford orgs
      class StanfordOrganizationsJsonReader < TrajectPlus::JsonReader
        def each(&block)
          yield_children(json, block)
        end

        private

        def yield_children(hash, block)
          block.call(hash)
          children = children_path(hash)
          return if children.blank?
          children.each do |child|
            yield_children(child, block)
          end
        end

        def children_path(hash)
          JsonPath.on(hash, '$.children').first
        end
      end
    end
  end
end
