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
  #provide 'writer_class_name', 'Traject::JsonWriter'
  provide 'reader_class_name', 'Rialto::Etl::Readers::NDJsonReader'
end

# The named graph to place these triples into.
to_field '@graph', literal(STANFORD_GRANTS_GRAPH.to_s), single: true
to_field '@type', literal("#{VIVO['Grant']}"), single: true

to_field '@id', lambda { |json, accum|
  accum << RIALTO_GRANTS[json['spoNumber']]
}, single: true

to_field "!#{RDF::Vocab::RDFS['label']}", extract_json('$.projectTitle'), single: true
to_field "!#{RDF::Vocab::SKOS['prefLabel']}", extract_json('$.projectTitle'), single: true
to_field "!#{FRAPO['hasStartDate']}", extract_json('$.projectStartDate'), single: true
to_field "!#{FRAPO['hasEndDate']}", extract_json('$.projectEndDate'), single: true
to_field "!#{VIVO['assignedBy']}", extract_json('$.directSponsorName'), single: true

to_field VIVO['relates'].to_s, lambda { |json, accum|
  person = RIALTO_PEOPLE[json['piEmployeeId']]
  pi_role = RIALTO_CONTEXT_ROLES["#{json['spoNumber']}_#{json['piEmployeeId']}"]
  accum << {
              '@id' => pi_role,
              '@type' => VIVO['PrincipalInvestigatorRole'],
              "!{VIVO['relates'}" => true,
              OBO['RO_0000052'].to_s => person,
              "#person_to_role" => {
                                     '@id' => person,
                                     OBO['RO_0000053'].to_s => pi_role
                                   },
              VIVO['relatedBy'].to_s => RIALTO_GRANTS[json['spoNumber']]
           }

  accum << {
              '@id' => person,
              VIVO['relatedBy'].to_s => RIALTO_GRANTS[json['spoNumber']]
           }
}
