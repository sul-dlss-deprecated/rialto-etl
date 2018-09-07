# frozen_string_literal: true

require 'traject_plus'
require 'rialto/etl/readers/ndjson_reader'

extend TrajectPlus::Macros
extend TrajectPlus::Macros::JSON

settings do
  provide 'writer_class_name', 'Traject::JsonWriter'
  provide 'reader_class_name', 'Rialto::Etl::Readers::NDJsonReader'
end

to_field 'http://purl.org/ontology/bibo/doi',
         extract_json("$.dynamic_data.cluster_related.identifiers.identifier[?(@.type=='doi')].value"), single: true
to_field '@id',
         extract_json('$.UID'),
         transform: transform(prepend: 'http://rialto.stanford.edu/publications/'),
         single: true
to_field '@type', lambda { |_json, accum|
                    accum.concat(['http://purl.org/ontology/bibo/Document'])
                  }
to_field 'http://purl.org/ontology/bibo/abstract',
         extract_json('$.static_data.fullrecord_metadata.abstracts.abstract.abstract_text.p')
to_field 'http://purl.org/dc/terms/title',
         extract_json("$.static_data.summary.titles.title[?(@.type=='item')].content")

# [
#   {
#     "grant_ids": {
#       "grant_id": [
#         "GM102365",
#         "LM05652",
#         "GM61374"
#       ],
#       "count": 3
#     },
#     "grant_agency": "NIH"
#   },
#   {
#     "grant_ids": {
#       "count": 1,
#       "grant_id": "U01FD004979"
#     },
#     "grant_agency": "FDA"
#   }
# ]
# to_field 'http://vivoweb.org/ontology/core#hasFundingVehicle',
#          extract_json('$.static_data.fullrecord_metadata.fund_ack.grants.grant'),
#          transform: lambda { |o, tw, thre|
#            # We want to parse grant agency/id
#            $stderr.puts "in transform #{o}, #{tw}, #{thre}"
#          }

# Build vivo:Authorship with this
# to_field 'http://vivoweb.org/ontology/core#relatedBy',
#          extract_json("$.static_data.summary.names.name[?(@.role=='author')]")
