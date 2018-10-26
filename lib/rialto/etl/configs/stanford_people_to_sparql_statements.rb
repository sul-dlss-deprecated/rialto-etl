# frozen_string_literal: true

require 'traject_plus'
require 'rialto/etl/readers/ndjson_reader'
require 'rialto/etl/writers/sparql_statement_writer'
require 'rialto/etl/namespaces'
require 'rialto/etl/transformers/people'
require 'rialto/etl/transformers/addresses'

extend TrajectPlus::Macros
extend TrajectPlus::Macros::JSON
extend Rialto::Etl::NamedGraphs
extend Rialto::Etl::Vocabs

def full_name(json)
  Rialto::Etl::Transformers::People.fullname_from_names(given_name: JsonPath.on(json, '$.names.preferred.firstName').first,
                                                        middle_name: JsonPath.on(json, '$.names.preferred.middleName').first,
                                                        family_name: JsonPath.on(json, '$.names.preferred.lastName').first)
end

settings do
  provide 'writer_class_name', 'Rialto::Etl::Writers::SparqlStatementWriter'
  # For development, may want to use following writer:
  # provide 'writer_class_name', 'Traject::JsonWriter'
  provide 'reader_class_name', 'Rialto::Etl::Readers::NDJsonReader'
end

# The named graph to place these triples into.
to_field '@graph', literal(STANFORD_PEOPLE_GRAPH.to_s), single: true

# Subject
to_field '@id', lambda { |json, accum|
  accum << RIALTO_PEOPLE[json['profileId']]
}, single: true

# Person types
to_field '@type', lambda { |json, accum|
  person_types = [RDF::Vocab::FOAF.Agent, RDF::Vocab::FOAF.Person]
  person_types << Stanford.PhdStudent if JsonPath.on(json, '$.affiliations.capPhdStudent').first
  person_types << Stanford.MsStudent if JsonPath.on(json, '$.affiliations.capMsStudent').first
  person_types << Stanford.MdStudent if JsonPath.on(json, '$.affiliations.capMdStudent').first
  person_types << Stanford.Faculty if JsonPath.on(json, '$.affiliations.capFaculty').first
  person_types << Stanford.Fellow if JsonPath.on(json, '$.affiliations.capFellow').first
  person_types << Stanford.Resident if JsonPath.on(json, '$.affiliations.capResident').first
  person_types << Stanford.Postdoc if JsonPath.on(json, '$.affiliations.capPostdoc').first
  person_types << Stanford.Physician if JsonPath.on(json, '$.affiliations.physician').first
  person_types << Stanford.Staff if JsonPath.on(json, '$.affiliations.capStaff').first

  accum.concat(person_types)
}

# Person label
to_field "!#{RDF::Vocab::SKOS.prefLabel}", literal(true)
to_field RDF::Vocab::SKOS.prefLabel.to_s, lambda { |json, accum|
  accum << full_name(json)
}, single: true
to_field "!#{RDF::Vocab::RDFS.label}", literal(true)
to_field RDF::Vocab::RDFS.label.to_s, lambda { |json, accum|
  accum << full_name(json)
}, single: true
# Alternate labels
to_field "!#{RDF::Vocab::SKOS.altLabel}", literal(true)
to_field RDF::Vocab::SKOS.altLabel.to_s, lambda { |json, accum|
  name_json = JsonPath.on(json, '$.names.preferred').first
  if name_json
    accum << Rialto::Etl::Transformers::People.name_variations_from_names(given_name: name_json['firstName'],
                                                                          middle_name: name_json['middleName'],
                                                                          family_name: name_json['lastName'])
  end
}, single: true

# Person name (Vcard)
to_field "!#{RDF::Vocab::VCARD.hasName}", literal(true), single: true
to_field RDF::Vocab::VCARD.hasName.to_s, lambda { |json, accum|
  name_json = JsonPath.on(json, '$.names.preferred').first
  if name_json
    accum << Rialto::Etl::Transformers::People.construct_name_vcard(id: json['profileId'],
                                                                    given_name: name_json['firstName'],
                                                                    middle_name: name_json['middleName'],
                                                                    family_name: name_json['lastName'])
  end
}, single: true

# Bio
to_field "!#{VIVO.overview}", literal(true), single: true
to_field VIVO.overview.to_s, extract_json('$.bio.text'), single: true

# Person country
to_field RDF::Vocab::DC.spatial.to_s, lambda { |_, accum|
  country = Rialto::Etl::Transformers::Addresses.construct_country(country: 'United States')
  accum << country unless country.nil?
}, single: true

# Note: There is also relatedBy for positions.
to_field VIVO.relatedBy.to_s, lambda { |json, accum|
  advisees_json = JsonPath.on(json, '$.advisees[*].advisee')
  advisees = []
  advisees_json.each do |advisee_json|
    advisees << {
      '@id' => RIALTO_CONTEXT_RELATIONSHIPS["#{advisee_json['profileId']}_#{json['profileId']}"],
      '@type' => VIVO.AdvisingRelationship,
      RDF::Vocab::DC.valid.to_s => Time.now.to_date
    }
  end
  accum.concat(advisees)
}

to_field OBO['RO_0000053'].to_s, lambda { |json, accum|
  unless JsonPath.on(json, '$.advisees').empty?
    accum << {
      '@id' => RIALTO_CONTEXT_ROLES['AdvisorRole'],
      '@type' => VIVO.AdvisorRole,
      # This points back at the advisor
      OBO['RO_0000052'].to_s => RIALTO_PEOPLE[json['profileId']]
    }
  end
}

to_field '#advisees', lambda { |json, accum|
  advisees_json = JsonPath.on(json, '$.advisees[*].advisee')
  advisees = []
  advisees_json.each do |advisee_json|
    advisee_hash = Rialto::Etl::Transformers::People.construct_person(id: advisee_json['profileId'],
                                                                      given_name: advisee_json['firstName'],
                                                                      family_name: advisee_json['lastName'])
    # Related by
    advisee_hash[VIVO.relatedBy.to_s] = RIALTO_CONTEXT_RELATIONSHIPS["#{advisee_json['profileId']}_#{json['profileId']}"]
    # Advisee role
    advisee_hash[OBO['RO_0000053'].to_s] = {
      '@id' => RIALTO_CONTEXT_ROLES['AdviseeRole'],
      '@type' => VIVO.AdviseeRole,
      # This points back at the advisee
      OBO['RO_0000052'].to_s => RIALTO_PEOPLE[advisee_json['profileId']]
    }
    advisees << advisee_hash
  end
  accum << advisees unless advisees.empty?
}, single: true

# Email
to_field "!#{RDF::Vocab::VCARD.hasEmail}", literal(true)
to_field RDF::Vocab::VCARD.hasEmail.to_s, extract_json('$.primaryContact.email'), single: true

# SUNet Id
to_field RDF::Vocab::DC.identifier.to_s, lambda { |json, accum|
  if (sunet_id = JsonPath.on(json, '$.uid').first)
    accum << RDF::Literal.new(sunet_id, datatype: RIALTO_CONTEXT_IDENTIFIERS['Sunetid'])
  end
}, single: true

# Person positions
to_field VIVO.relatedBy.to_s, lambda { |json, accum|
  titles_json = JsonPath.on(json, '$.titles').first
  positions = Rialto::Etl::Transformers::People.construct_stanford_positions(titles: titles_json, profile_id: json['profileId'])
  accum.concat(positions) if positions.any?
}
