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
  provide 'writer_class_name', 'Rialto::Etl::Writers::SparqlStatementWriter'
  # provide 'writer_class_name', 'Traject::JsonWriter'
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
  person_types = [FOAF['Agent'], FOAF['Person']]
  person_types << VIVO['Student'] if JsonPath.on(json, '$.affiliations.capPhdStudent').first == true ||
                                     JsonPath.on(json, '$.affiliations.capMsStudent').first == true ||
                                     JsonPath.on(json, '$.affiliations.capMdStudent').first == true
  person_types << VIVO['FacultyMember'] if JsonPath.on(json, '$.affiliations.capFaculty').first
  person_types << VIVO['NonFacultyAcademic'] if JsonPath.on(json, '$.affiliations.capFellow').first == true ||
                                                JsonPath.on(json, '$.affiliations.capResident').first == true ||
                                                JsonPath.on(json, '$.affiliations.capPostdoc').first == true
  person_types << VIVO['NonAcademic'] if JsonPath.on(json, '$.affiliations.physician').first == true ||
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
compose '@person_name', ->(json, acc, _context) { acc << json } do
  require 'traject_plus'
  extend TrajectPlus::Macros
  extend TrajectPlus::Macros::JSON
  to_field VCARD['given-name'].to_s, extract_json('$.names.preferred.firstName'), single: true
  to_field VCARD['middle-name'].to_s, extract_json('$.names.preferred.middleName'), single: true
  to_field VCARD['family-name'].to_s, extract_json('$.names.preferred.lastName'), single: true
end
# TODO: Is there a way to make this single?

# Bio
to_field '!' + VIVO['overview'].to_s, literal(true)
to_field VIVO['overview'].to_s, extract_json('$.bio.text'), single: true

# Person address
to_field '!person_address', literal(true), single: true
compose '@person_address',
        ->(json, acc, _context) { acc << JsonPath.on(json, '$.contacts[?(@["type"] == "academic")]').first } do
  require 'traject_plus'
  extend TrajectPlus::Macros
  extend TrajectPlus::Macros::JSON
  to_field VCARD['street-address'].to_s, extract_json('$.address'), single: true
  to_field VCARD['locality'].to_s, extract_json('$.city'), single: true
  to_field VCARD['region'].to_s, extract_json('$.state'), single: true
  to_field VCARD['postal-code'].to_s, extract_json('$.zip'), single: true
  # Punting on looking up country based on postal code (http://www.geonames.org/export/web-services.html) and
  # hardcoding to US (http://sws.geonames.org/6252001/)
  to_field VCARD['country-name'].to_s, literal('United States'), single: true
  to_field DCTERMS['spatial'].to_s, literal(RDF::URI.new('http://sws.geonames.org/6252001/')), single: true
end

# # TODO: Person position. Depends on mapping departments.

# Advisees
# Deleteting advisees not currently supported since logic not clear.
# to_field '!advisees', literal(true), single: true
to_field '@advisees', lambda { |json, accum|
  advisees_json = JsonPath.on(json, '$.advisees')
  unless advisees_json.empty?
    advisees_json[0].each do |advisee_json|
      advisee_hash = {}
      advisee_hash['@id'] = JsonPath.on(advisee_json, '$.advisee.profileId').first
      advisee_hash['@id_ns'] = RIALTO_PEOPLE.to_s
      advisee_hash['@type'] = [FOAF['Agent'], FOAF['Person']]
      advisee_hash['!type'] = true
      name_vcard_hash = {}
      name_vcard_hash[VCARD['given-name'].to_s] = JsonPath.on(advisee_json, '$.advisee.firstName').first
      name_vcard_hash[VCARD['family-name'].to_s] = JsonPath.on(advisee_json, '$.advisee.lastName').first
      advisee_hash['@person_name'] = [name_vcard_hash]
      advisee_hash['!person_name'] = true
      accum << advisee_hash
    end
  end
}
