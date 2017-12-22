# frozen_string_literal: true

extend TrajectPlus::Macros
extend TrajectPlus::Macros::JSON

settings do
  provide 'writer_class_name', 'JsonWriter'
  provide 'reader_class_name', 'Rialto::Etl::StanfordOrganizationsJsonReader'
end

# context_object = {
#   '@context' => {
#     obo: 'http://purl.obolibrary.org/obo/',
#     rdfs: 'http://www.w3.org/2000/01/rdf-schema#',
#     vcard: 'http://www.w3.org/2006/vcard/ns#',
#     vivo: 'http://vivoweb.org/ontology/core#',
#     stanford: 'http://authorities.stanford.edu/orgs#'
#   }
# }

# puts context_object.to_json
to_field '@id', extract_json('$.alias'), transform: transform(prepend: 'http://authorities.stanford.edu/orgs#'), single: true
to_field '@type', extract_json('$.type', translation_map: 'stanford_organizations_to_vivo_types'), single: true
to_field 'rdfs:label', extract_json('$.name'), single: true
to_field 'rdfs:seeAlso', extract_json('$.url'), single: true
to_field 'vivo:abbreviation', extract_json('$.orgCodes'), single: true
