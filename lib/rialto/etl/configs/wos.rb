# frozen_string_literal: true

require 'digest'
require 'traject_plus'
require 'rialto/etl/readers/ndjson_reader'
require 'active_support/core_ext/array/wrap'

extend TrajectPlus::Macros
extend TrajectPlus::Macros::JSON

# Do a lookup using the entity resolution service.
# @param [String] type the type of entity
# @param [Hash] params the values to query for.
# @return [String] the uri for the resource
def resolve_entity(type, params)
  Rialto::Etl::ServiceClient::EntityResolver.resolve(type, params)
end

# Find all of the addresses and index them by addr_no into a Hash.
def fetch_addresses(json)
  addresses = Array.wrap(JsonPath.on(json, '$.static_data.fullrecord_metadata.addresses.address_name').first)
  addresses.each_with_object({}) do |addr_name, h|
    addr = addr_name['address_spec']
    result = parse_address(addr)
    h[addr.fetch('addr_no')] = result
  end
end

def parse_address(addr)
  result = addr.slice('country')
  org = addr.fetch('organizations').fetch('organization')
  label = case org
          when String
            org
          when Array
            org.find { |o| o['pref'] == 'Y' }['content']
          end
  result['organization'] = label
  result
end

# @param addresses [Hash] a lookup between the addr_no and the data
# @param addr_id [Integer,String,NilClass] the address identifier to lookup
# @return [Hash,NilClass] the address for the provided identifier
def lookup_address(addresses, addr_id)
  ### addr_no could be an integer or a space delimited string.
  address_id = case addr_id
               when String
                 addr_id.split(' ').map(&:to_i).first
               when Integer
                 addr_id
               end
  return unless address_id # it may be nil
  addresses[address_id]
end

settings do
  provide 'writer_class_name', 'Traject::JsonWriter'
  provide 'reader_class_name', 'Rialto::Etl::Readers::NDJsonReader'
  # provide 'processing_thread_pool', 0 # Turns off multithreading, for debugging
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
to_field 'http://vivoweb.org/ontology/core#relatedBy', lambda { |json, accumulator|
  addresses = fetch_addresses(json)
  # Lookup all the contributors in the entity resolution service to find their URIs.
  contributors = Array.wrap(JsonPath.on(json, '$.static_data.summary.names.name').first)
  people_uris = contributors.map do |c|
    address = lookup_address(addresses, c['addr_no'])
    person_params = c.slice('orcid_id', 'first_name', 'last_name', 'full_name')
    person_params.merge!(address) if address
    { '@id' => resolve_entity('person', person_params) }
  end
  accumulator << { '@type' => 'http://vivoweb.org/ontology/core#Authorship',
                   'http://vivoweb.org/ontology/core#relates' => people_uris }
}, single: true
to_field 'http://purl.org/dc/terms/subject', lambda { |json, accumulator|
  subjects = JsonPath.on(json, "$.static_data.fullrecord_metadata.category_info.subjects.subject[?(@.ascatype=='extended')].content")
  accumulator << subjects.map do |subject|
    resolve_entity('topic', name: subject)
  end
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
