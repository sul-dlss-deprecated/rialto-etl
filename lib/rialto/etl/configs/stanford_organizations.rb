# frozen_string_literal: true

require 'traject_plus'
require 'rialto/etl/readers/stanford_organizations_json_reader'
require 'rialto/etl/writers/ntriples_writer'

extend TrajectPlus::Macros
extend TrajectPlus::Macros::JSON

settings do
  provide 'writer_class_name', 'Rialto::Etl::Writers::NtriplesWriter'
  provide 'reader_class_name', 'Rialto::Etl::Readers::StanfordOrganizationsJsonReader'
end

to_field '@id', extract_json('$.alias'), transform: transform(prepend: 'http://authorities.stanford.edu/orgs#'), single: true
to_field '@type', extract_json('$.type', translation_map: 'stanford_organizations_to_vivo_types'), single: true
to_field 'http://www.w3.org/2000/01/rdf-schema#label', extract_json('$.name'), single: true
to_field 'http://www.w3.org/2000/01/rdf-schema#seeAlso', extract_json('$.url'), single: true
to_field 'http://vivoweb.org/ontology/core#abbreviation', extract_json('$.orgCodes'), single: true
