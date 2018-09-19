# frozen_string_literal: true

require 'traject_plus'
require 'rialto/etl/readers/stanford_organizations_json_reader'
require 'rialto/etl/writers/sparql_statement_writer'
require 'rialto/etl/namespaces'

extend TrajectPlus::Macros
extend TrajectPlus::Macros::JSON
extend Rialto::Etl::NamedGraphs
extend Rialto::Etl::Vocabs

def contextualized_organization_name(organization)
  return organization['name'] if organization['parent'].nil? || organization['parent']['name'] == 'Stanford University'
  "#{organization['name']} (#{organization['parent']['name']})"
end

settings do
  provide 'writer_class_name', 'Rialto::Etl::Writers::SparqlStatementWriter'
  provide 'reader_class_name', 'Rialto::Etl::Readers::StanfordOrganizationsJsonReader'
end

# The named graph to place these triples into.
to_field '@graph', literal(STANFORD_ORGANIZATIONS_GRAPH.to_s), single: true

# Subject
to_field '@id', extract_json('$.alias'), single: true
to_field '@id_ns', literal(RIALTO_ORGANIZATIONS.to_s), single: true

# Org types
to_field '!type', literal(true), single: true
to_field '@type', lambda { |json, accum|
  org_types = [FOAF.Agent, FOAF['Organization']]
  org_types << case JsonPath.on(json, '$.type').first
               when 'DEPARTMENT'
                 VIVO['Department']
               when 'DIVISION'
                 VIVO['Division']
               when 'ROOT'
                 VIVO['University']
               when 'SCHOOL'
                 VIVO['School']
               when 'SUB_DIVISION'
                 VIVO['Division']
               else
                 VIVO['Department']
               end
  accum.concat(org_types)
}

# Org label
to_field '!label', literal(true)
to_field '@label', lambda { |json, accum|
  accum << contextualized_organization_name(json)
}, single: true

# Org codes
to_field '!' + DCTERMS.identifier.to_s, literal(true)
to_field DCTERMS.identifier.to_s, extract_json('$.orgCodes'), single: true

# Parent
to_field '!' + OBO['BFO_0000050'].to_s, literal(true)
to_field OBO['BFO_0000050'].to_s, lambda { |json, accum|
  parent = JsonPath.on(json, '$.parent.alias').first
  accum << RIALTO_ORGANIZATIONS[parent] if parent
}

# TODO: Children
