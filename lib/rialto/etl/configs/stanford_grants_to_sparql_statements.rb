# frozen_string_literal: true

require 'traject_plus'
require 'rialto/etl/readers/ndjson_reader'
require 'rialto/etl/writers/sparql_statement_writer'
require 'rialto/etl/namespaces'
require 'rialto/etl/transformers/people'
require 'rialto/etl/logging'

extend TrajectPlus::Macros
extend TrajectPlus::Macros::JSON
extend Rialto::Etl::NamedGraphs
extend Rialto::Etl::Vocabs

settings do
  provide 'writer_class_name', 'Rialto::Etl::Writers::SparqlStatementWriter'
  provide 'reader_class_name', 'Rialto::Etl::Readers::NDJsonReader'
end

# The named graph to place these triples into.
to_field '@graph', literal(STANFORD_GRANTS_GRAPH.to_s), single: true
to_field '@type', literal(VIVO['Grant']), single: true

to_field '@id', lambda { |json, accum|
  accum << RIALTO_GRANTS[json['spoNumber']]
}, single: true

to_field '!' + RDF::Vocab::RDFS.label.to_s, literal(true)
to_field RDF::Vocab::RDFS.label.to_s, extract_json('$.projectTitle'), single: true
to_field '!' + RDF::Vocab::SKOS.prefLabel.to_s, literal(true)
to_field RDF::Vocab::SKOS.prefLabel.to_s, extract_json('$.projectTitle'), single: true

to_field '!' + FRAPO.hasStartDate.to_s, literal(true)
to_field FRAPO.hasStartDate.to_s, lambda { |json, accum|
  accum << RDF::Literal::Date.new(JsonPath.on(json, '$.projectStartDate').first[0..9])
}, single: true
to_field '!' + FRAPO.hasEndDate.to_s, literal(true)
to_field FRAPO.hasEndDate.to_s, lambda { |json, accum|
  accum << RDF::Literal::Date.new(JsonPath.on(json, '$.projectEndDate').first[0..9])
}, single: true

to_field '!' + VIVO['assignedBy'], literal(true)
to_field VIVO['assignedBy'].to_s, lambda { |json, accum|
  org_name = JsonPath.on(json, '$.directSponsorName').first
  accum << Rialto::Etl::Transformers::Organizations.resolve_or_construct_org(org_name: org_name) if org_name
}, single: true

# See https://wiki.duraspace.org/display/VTDA/VIVO-ISF+1.6+relationship+diagrams%3A+Grant
to_field VIVO['relates'].to_s, lambda { |json, accum|
  person = RIALTO_PEOPLE[json['piEmployeeId']]
  pi_role = RIALTO_CONTEXT_ROLES["#{json['spoNumber']}_#{json['piEmployeeId']}"]

  # Adding grant-relates-to-pi-role
  accum << {
    '@id' => pi_role,
    '@type' => VIVO['PrincipalInvestigatorRole'],
    "!{VIVO['relates'}" => true,
    OBO['RO_0000052'].to_s => person,
    '#person_to_role' => {
      '@id' => person,
      OBO['RO_0000053'].to_s => pi_role
    },
    VIVO['relatedBy'].to_s => RIALTO_GRANTS[json['spoNumber']]
  }

  # Adding grant-relates-to-person
  accum << {
    '@id' => person,
    VIVO['relatedBy'].to_s => RIALTO_GRANTS[json['spoNumber']]
  }
}
