# frozen_string_literal: true

require 'traject_plus'
require 'rialto/etl/readers/ndjson_reader'
require 'rialto/etl/writers/sparql_statement_writer'
require 'rialto/etl/namespaces'

extend TrajectPlus::Macros
extend TrajectPlus::Macros::JSON
extend Rialto::Etl::NamedGraphs
extend Rialto::Etl::Vocabs

settings do
  # provide 'writer_class_name', 'Rialto::Etl::Writers::SparqlStatementWriter'
  provide 'writer_class_name', 'Traject::JsonWriter'
  provide 'reader_class_name', 'Rialto::Etl::Readers::NDJsonReader'
end

# The named graph to place these triples into.
to_field '@graph', literal(STANFORD_PEOPLE_GRAPH.to_s), single: true

# Subject
to_field '@id', extract_json('$.profileId'), single: true
to_field '@id_ns', literal(RIALTO_PEOPLE.to_s), single: true

# Person types
to_field '!type', literal(true), single: true
to_field '@type', lambda { |json, accum|
  person_types = [FOAF.Agent, FOAF.Person]
  person_types << VIVO.Student if JsonPath.on(json, '$.affiliations.capPhdStudent').first == true ||
                                  JsonPath.on(json, '$.affiliations.capMsStudent').first == true ||
                                  JsonPath.on(json, '$.affiliations.capMdStudent').first == true
  person_types << VIVO.FacultyMember if JsonPath.on(json, '$.affiliations.capFaculty').first == true
  person_types << VIVO.NonFacultyAcademic if JsonPath.on(json, '$.affiliations.capFellow').first == true ||
                                             JsonPath.on(json, '$.affiliations.capResident').first == true ||
                                             JsonPath.on(json, '$.affiliations.capPostdoc').first == true
  person_types << VIVO.NonAcademic if JsonPath.on(json, '$.affiliations.physician').first == true ||
                                      JsonPath.on(json, '$.affiliations.capStaff').first == true
  accum.concat(person_types)
}

# Person label
to_field '!label', literal(true)
to_field '@label', lambda { |json, accum|
  name_parts = [JsonPath.on(json, '$.names.preferred.firstName').first]
  name_parts << JsonPath.on(json, '$.names.preferred.middleName').first
  name_parts << JsonPath.on(json, '$.names.preferred.lastName').first
  accum << name_parts.compact.join(' ')
}, single: true

# Person name (Vcard)
to_field '!person_name', literal(true), single: true
compose '@person_name', ->(rec, acc, _context) { acc << rec } do
  require 'traject_plus'
  extend TrajectPlus::Macros
  extend TrajectPlus::Macros::JSON
  to_field VCARD['given-name'].to_s, extract_json('$.names.preferred.firstName'), single: true
  to_field VCARD['middle-name'].to_s, extract_json('$.names.preferred.middleName'), single: true
  to_field VCARD['family-name'].to_s, extract_json('$.names.preferred.lastName'), single: true
end
# TODO: Is there a way to make this single?

# Bio
to_field '!' + VIVO.overview.to_s, literal(true)
to_field VIVO.overview.to_s, extract_json('$.bio.text'), single: true

# TODO: Person address. Depends on geonames lookup
# TODO: Person position. Depends on mapping departments.
