# frozen_string_literal: true

require 'traject_plus'
require 'rialto/etl/readers/ndjson_reader'
require 'rialto/etl/writers/sparql_statement_writer'
require 'rialto/etl/namespaces'
require 'traject/csv_writer'

extend TrajectPlus::Macros
extend TrajectPlus::Macros::JSON
extend Rialto::Etl::NamedGraphs
extend Rialto::Etl::Vocabs

settings do
  provide 'delimited_writer.fields', 'uri,first_name,last_name,sunetid'
  provide 'writer_class_name', 'Traject::CSVWriter'
  provide 'reader_class_name', 'Rialto::Etl::Readers::NDJsonReader'
end

# The named graph to place these triples into.
to_field 'uri' do |json, accum|
  accum << Rialto::Etl::Vocabs::RIALTO_PEOPLE[JsonPath.on(json, '$.profileId').first].to_s.dup
end

# Names
to_field 'first_name', extract_json('$.names.preferred.firstName'), single: true
to_field 'last_name', extract_json('$.names.preferred.lastName'), single: true

# SUNet Id
to_field 'sunetid', extract_json('$.uid'), single: true
