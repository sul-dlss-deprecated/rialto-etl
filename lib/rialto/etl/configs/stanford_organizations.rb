# frozen_string_literal: true

extend TrajectPlus::Macros
extend TrajectPlus::Macros::JSON

settings do
  provide 'writer_class_name', 'Rialto::Etl::Writers::StanfordOrganizationsJsonldWriter'
  provide 'reader_class_name', 'Rialto::Etl::Readers::StanfordOrganizationsJsonReader'
end

to_field '@id', extract_json('$.alias'), transform: transform(prepend: 'http://authorities.stanford.edu/orgs#'), single: true
to_field '@type', extract_json('$.type', translation_map: 'stanford_organizations_to_vivo_types'), single: true
to_field 'rdfs:label', extract_json('$.name'), single: true
to_field 'rdfs:seeAlso', extract_json('$.url'), single: true
to_field 'vivo:abbreviation', extract_json('$.orgCodes'), single: true
