# frozen_string_literal: true

require 'digest'
require 'traject_plus'
require 'rialto/etl/readers/ndjson_reader'

extend TrajectPlus::Macros
extend TrajectPlus::Macros::JSON

settings do
  provide 'writer_class_name', 'Traject::JsonWriter'
  provide 'reader_class_name', 'Rialto::Etl::Readers::NDJsonReader'
end

to_field '@id', lambda { |json, accumulator|
  source_id = JsonPath.on(json, '$.UID').first
  subject_uri = "http://sul.stanford.edu/rialto/publications/#{Digest::MD5.hexdigest(source_id)}"
  accumulator << subject_uri
}, single: true
to_field '@type',
         extract_json('$.static_data.fullrecord_metadata.normalized_doctypes.doctype',
                      translation_map: 'wos_document_types_to_rialto'),
         single: true
to_field 'http://purl.org/ontology/bibo/abstract', lambda { |json, accumulator|
  abstracts = JsonPath.on(json, '$.static_data.fullrecord_metadata.abstracts.abstract.abstract_text.p')
  accumulator << abstracts.flatten.join(' ') unless abstracts.empty?
}, single: true
to_field 'http://purl.org/ontology/bibo/doi', lambda { |json, accumulator|
  doi = JsonPath.on(json, '$.dynamic_data.cluster_related.identifiers.identifier[?(@.type=="doi")].value').first ||
        JsonPath.on(json, '$.dynamic_data.cluster_related.identifiers.identifier[?(@.type=="xref_doi")].value').first
  accumulator << doi if doi
}, single: true
to_field 'http://purl.org/ontology/bibo/identifier',
         extract_json('$.dynamic_data.cluster_related.identifiers.identifier[*].value')
to_field 'http://purl.org/dc/terms/hasPart',
         extract_json("$.static_data.summary.titles.title[?(@.type=='source')].content"),
         single: true
to_field 'http://vivoweb.org/ontology/core#publisher',
         extract_json('$.static_data.summary.publishers.publisher.names.name.display_name'),
         single: true
to_field 'http://purl.org/dc/terms/title',
         extract_json("$.static_data.summary.titles.title[?(@.type=='item')].content"),
         single: true
to_field 'http://purl.org/dc/terms/created',
         extract_json('$.static_data.summary.pub_info.sortdate'),
         single: true
