# frozen_string_literal: true

require 'digest'
require 'cgi'
require 'traject_plus'
require 'rialto/etl/readers/ndjson_reader'
require 'rialto/etl/writers/sparql_statement_writer'
require 'rialto/etl/transformers/addresses'
require 'rialto/etl/transformers/grants'
require 'rialto/etl/transformers/people'
require 'active_support/core_ext/array/wrap'
require 'rialto/etl/namespaces'

extend TrajectPlus::Macros
extend TrajectPlus::Macros::JSON
extend Rialto::Etl::NamedGraphs
extend Rialto::Etl::Vocabs

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

# rubocop:disable Metrics/MethodLength
def parse_address(addr)
  result = addr.slice('country')
  if addr.key?('organizations')
    org = addr.fetch('organizations').fetch('organization')
    label = case org
            when String
              org
            when Array
              org.find { |o| o['pref'] == 'Y' }['content']
            end
    result['organization'] = label
  end
  result
end
# rubocop:enable Metrics/MethodLength

# Find the grant agencies
def fetch_grant_agencies(json)
  agencies = Array.wrap(JsonPath.on(json, '$.static_data.fullrecord_metadata.fund_ack.grants.grant').first).map do |grant|
    next if grant.fetch('grant_agency', []).empty?
    grant['grant_agency']
  end
  agencies.compact
end

# Find the grant identifiers
def fetch_grant_identifiers(json)
  Array.wrap(
    JsonPath.on(json, '$.static_data.fullrecord_metadata.fund_ack.grants.grant[*].grant_ids.grant_id').flatten
  ).reject { |id| id.to_s.empty? || id.nil? }.map(&:to_s)
end

# Return the names of the publishers
def fetch_publishers(json)
  JsonPath.on(json, '$.static_data.summary.publishers.publisher.names.name.display_name')
end

# Returns a person for a contributor
# rubocop:disable Metrics/MethodLength
def construct_contributor(name, addresses)
  address = lookup_address(addresses, name['addr_no'])
  person_params = name.slice('orcid_id', 'first_name', 'last_name', 'full_name')
  person_params.merge!(address) if address
  person = Rialto::Etl::Transformers::People.resolve_or_construct_person(given_name: name['first_name'] || name['suffix'],
                                                                         family_name: name['last_name'],
                                                                         addl_params: person_params)

  # Note: Adding a country for each publication, so person may have many countries.
  if address&.key?('country') &&
     (country = Rialto::Etl::Transformers::Addresses.construct_country(country: address['country']))
    person[RDF::Vocab::DC.spatial.to_s] = country
  end

  # If there is an organization, add a position for the person
  if address&.key?('organization')
    person_id = remove_vocab_from_uri(RIALTO_PEOPLE, person['@id'])
    person['#organization'] = Rialto::Etl::Transformers::People.construct_position(org_name: address['organization'],
                                                                                   person_id: person_id)
  end
  person
end
# rubocop:enable Metrics/MethodLength

# Lookup the address from this document by the internal (to the document) addr_id
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
  provide 'writer_class_name', 'Rialto::Etl::Writers::SparqlStatementWriter'
  provide 'reader_class_name', 'Rialto::Etl::Readers::NDJsonReader'
  # provide 'processing_thread_pool', 0 # Turns off multithreading, for debugging
end

# The named graph to place these triples into.
to_field '@graph', literal(WOS_GRAPH.to_s), single: true

to_field '@id', lambda { |json, accumulator|
  source_id = JsonPath.on(json, '$.UID').first
  subject_uri = "http://sul.stanford.edu/rialto/publications/#{Digest::MD5.hexdigest(source_id)}"
  accumulator << subject_uri
}, single: true

to_field '@type',
         extract_json('$.static_data.fullrecord_metadata.normalized_doctypes.doctype',
                      translation_map: 'wos_document_types_to_rialto') do |_, accumulator|
  accumulator.map! { |type| RDF::URI.new(type) }
end

to_field '@type', literal(RDF::Vocab::BIBO.Document)

to_field "!#{RDF::Vocab::BIBO.abstract}", literal(true), single: true
to_field RDF::Vocab::BIBO.abstract.to_s, lambda { |json, accumulator|
  abstracts = JsonPath.on(json, '$.static_data.fullrecord_metadata.abstracts.abstract.abstract_text.p')
  accumulator << abstracts.flatten.join(' ') unless abstracts.empty?
}, single: true

to_field "!#{RDF::Vocab::BIBO.doi}", literal(true), single: true
to_field RDF::Vocab::BIBO.doi.to_s, lambda { |json, accumulator|
  doi = JsonPath.on(json, '$.dynamic_data.cluster_related.identifiers.identifier[?(@.type=="doi")].value').first ||
        JsonPath.on(json, '$.dynamic_data.cluster_related.identifiers.identifier[?(@.type=="xref_doi")].value').first
  accumulator << RDF::URI("https://doi.org/#{CGI.escape(doi)}") if doi
}, single: true

to_field "!#{VIVO.relatedBy}", literal(true), single: true
to_field VIVO.relatedBy.to_s, lambda { |json, accumulator|
  addresses = fetch_addresses(json)
  # Lookup all the contributors in the entity resolution service to find their URIs.
  contributor_names = Array.wrap(JsonPath.on(json, '$.static_data.summary.names.name').first)
  accumulator << contributor_names.map do |name|
    next if name['role'] == 'corp'
    person = construct_contributor(name, addresses)
    {
      '@id' => RIALTO_CONTEXT_RELATIONSHIPS["#{json['UID']}_#{remove_vocab_from_uri(RIALTO_PEOPLE, person['@id'])}"],
      '@type' => name['role'] == 'book_editor' ? VIVO.Editorship : VIVO.Authorship,
      "!#{VIVO.relates}" => true,
      VIVO.relates.to_s => person['@id'],
      # Always add with # since always adding country for all people.
      '#person' => person
    }
  end
}, single: true

to_field "!#{RDF::Vocab::DC.subject}", literal(true), single: true
to_field RDF::Vocab::DC.subject.to_s, lambda { |json, accumulator|
  subjects = JsonPath.on(json, '$.static_data.fullrecord_metadata.category_info.subjects.' \
     "subject[?(@.ascatype=='extended')].content")
  accumulator << subjects.map do |subject|
    resolve_entity('topic', name: subject) || { '@id' => RIALTO_CONCEPTS[Digest::MD5.hexdigest(subject.downcase)],
                                                '@type' => RDF::Vocab::SKOS.Concept,
                                                RDF::Vocab::DC.subject.to_s => subject }
  end
}, single: true

to_field "!#{RDF::Vocab::BIBO.identifier}", literal(true), single: true
to_field RDF::Vocab::BIBO.identifier.to_s,
         extract_json('$.dynamic_data.cluster_related.identifiers.identifier[*].value')

to_field "!#{RDF::Vocab::DC.isPartOf}", literal(true), single: true
to_field RDF::Vocab::DC.isPartOf.to_s,
         extract_json("$.static_data.summary.titles.title[?(@.type=='source')].content"),
         single: true

to_field "!#{VIVO.publisher}", literal(true), single: true
to_field VIVO.publisher.to_s, lambda { |json, accumulator|
  accumulator << fetch_publishers(json).map do |name|
    Rialto::Etl::Transformers::Organizations.resolve_or_construct_org(org_name: name)
  end
}, single: true

to_field "!#{RDF::Vocab::DC.title}", literal(true), single: true
to_field RDF::Vocab::DC.title.to_s,
         extract_json("$.static_data.summary.titles.title[?(@.type=='item')].content"),
         single: true

to_field "!#{RDF::Vocab::DC.created}", literal(true), single: true
to_field RDF::Vocab::DC.created.to_s, lambda { |json, accumulator|
  accumulator << RDF::Literal::Date.new(JsonPath.on(json, '$.static_data.summary.pub_info.sortdate').first)
}, single: true

to_field "!#{VIVO.informationResourceSupportedBy}", literal(true), single: true
to_field VIVO.informationResourceSupportedBy.to_s, lambda { |json, accumulator|
  grant_agencies = fetch_grant_agencies(json)
  accumulator << grant_agencies.map do |agency|
    Rialto::Etl::Transformers::Organizations.resolve_or_construct_org(org_name: agency)
  end
}, single: true

to_field "!#{VIVO.hasFundingVehicle}", literal(true), single: true
to_field VIVO.hasFundingVehicle.to_s, lambda { |json, accumulator|
  grant_identifiers = fetch_grant_identifiers(json)
  accumulator << grant_identifiers.map do |identifier|
    Rialto::Etl::Transformers::Grants.resolve_grant(grant_identifier: identifier)
  end.compact
}, single: true
