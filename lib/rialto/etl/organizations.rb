# frozen_string_literal: true

require 'active_support/core_ext/class/attribute'

module Rialto
  module Etl
    # Loads a lookup table from organizations.json
    class Organizations
      class_attribute :organizations_data
      # default value
      self.organizations_data = 'organizations.json'

      def self.all
        extract_orgs(JSON.parse(File.read(organizations_data)))
      end

      def self.extract_orgs(org)
        orgs = {}
        org['orgCodes'].each { |org_code| orgs[org_code] = org['alias'] }
        org['children'].each { |child_org| orgs.merge!(extract_orgs(child_org)) } if org.key?('children')
        orgs
      end
      private_class_method :extract_orgs
    end
  end
end
