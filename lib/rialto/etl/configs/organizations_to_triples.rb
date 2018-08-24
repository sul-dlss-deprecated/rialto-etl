# frozen_string_literal: true

require 'traject_plus'
require 'rialto/etl/readers/ndjson_reader'
require 'rialto/etl/writers/organization_ntriples_writer'

extend TrajectPlus::Macros
extend TrajectPlus::Macros::JSON

# This takes in the Newline Delimited JSON, transforms it to JSON-LD, and writes it out as Ntriples

settings do
  provide 'writer_class_name', 'Rialto::Etl::Writers::OrganizationNtriplesWriter'
  provide 'reader_class_name', 'Rialto::Etl::Readers::NDJsonReader'
end

to_field '@id',
         extract_json('$.id'),
         transform: transform(prepend: 'http://rialto.stanford.edu/organizations/'),
         single: true
to_field '@type',
         extract_json('$.type', translation_map: 'stanford_organizations_to_vivo_types'),
         single: true
to_field 'parent',
         extract_json('$.parent'),
         transform: transform(prepend: 'http://rialto.stanford.edu/organizations/'),
         single: true
to_field 'http://www.w3.org/2000/01/rdf-schema#label',
         extract_json('$.name'),
         single: true
to_field 'http://vivoweb.org/ontology/core#abbreviation',
         extract_json('$.organization_codes'),
         single: true
to_field 'http://dbpedia.org/ontology/alias',
         extract_json('$.id'),
         single: true

to_field '@context', lambda { |_json, accum|
  accum.push(
    'parent' => {
      '@id' => 'http://purl.obolibrary.org/obo/BFO_0000050',
      '@type' => '@id'
    }
  )
}, single: true
