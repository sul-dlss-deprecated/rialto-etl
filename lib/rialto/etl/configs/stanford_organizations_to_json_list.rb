# frozen_string_literal: true

require 'traject_plus'
require 'rialto/etl/readers/stanford_organizations_json_reader'

extend TrajectPlus::Macros
extend TrajectPlus::Macros::JSON

settings do
  provide 'writer_class_name', 'Traject::JsonWriter'
  provide 'reader_class_name', 'Rialto::Etl::Readers::StanfordOrganizationsJsonReader'
end

to_field 'url', extract_json('$.url'), single: true
to_field 'id', extract_json('$.alias'), single: true
to_field 'type', extract_json('$.type'), single: true
to_field 'parent', extract_json('$.parent'), single: true
to_field 'name', extract_json('$.name'), single: true
to_field 'organization_codes', extract_json('$.orgCodes'), single: true
