# frozen_string_literal: true

require 'traject_plus'
require 'rialto/etl/readers/ndjson_reader'
require 'rialto/etl/writers/sparql_statement_writer'
require 'rialto/etl/namespaces'

extend TrajectPlus::Macros
extend TrajectPlus::Macros::JSON
extend Rialto::Etl::NamedGraphs
extend Rialto::Etl::Vocabs

def concat_name(json)
  name_parts = [JsonPath.on(json, '$.names.preferred.firstName').first]
  name_parts << JsonPath.on(json, '$.names.preferred.middleName').first
  name_parts << JsonPath.on(json, '$.names.preferred.lastName').first
  name_parts.compact.join(' ')
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
  person_types = [FOAF['Agent'], FOAF['Person']]
  person_types << VIVO['Student'] if JsonPath.on(json, '$.affiliations.capPhdStudent').first == true ||
                                     JsonPath.on(json, '$.affiliations.capMsStudent').first == true ||
                                     JsonPath.on(json, '$.affiliations.capMdStudent').first == true
  person_types << VIVO['FacultyMember'] if JsonPath.on(json, '$.affiliations.capFaculty').first
  person_types << VIVO['NonFacultyAcademic'] if JsonPath.on(json, '$.affiliations.capFellow').first == true ||
                                                JsonPath.on(json, '$.affiliations.capResident').first == true ||
                                                JsonPath.on(json, '$.affiliations.capPostdoc').first == true
  person_types << VIVO['NonAcademic'] if JsonPath.on(json, '$.affiliations.physician').first == true ||
                                         JsonPath.on(json, '$.affiliations.capStaff').first == true
  accum.concat(person_types)
}

# Person label
to_field "!#{SKOS['prefLabel']}", literal(true)
to_field SKOS['prefLabel'].to_s, lambda { |json, accum|
  accum << concat_name(json)
}, single: true
to_field "!#{RDFS['label']}", literal(true)
to_field RDFS['label'].to_s, lambda { |json, accum|
  accum << concat_name(json)
}, single: true

# Person name (Vcard)
to_field "!#{VCARD['hasName']}", literal(true), single: true
to_field VCARD['hasName'].to_s, lambda { |json, accum|
  name_json = JsonPath.on(json, '$.names.preferred').first
  if name_json
    accum << {
      '@id' => RIALTO_CONTEXT_NAMES[json['profileId']],
      '@type' => VCARD['Name'],
      "!#{VCARD['given-name']}" => true,
      VCARD['given-name'].to_s => name_json['firstName'],
      "!#{VCARD['middle-name']}" => true,
      VCARD['middle-name'].to_s => name_json['middleName'],
      "!#{VCARD['family-name']}" => true,
      VCARD['family-name'].to_s => name_json['lastName']
    }
  end
}, single: true

# Bio
to_field "!#{VIVO['overview']}", literal(true), single: true
to_field VIVO['overview'].to_s, extract_json('$.bio.text'), single: true

# Person address
to_field "!#{VCARD['hasAddress']}", literal(true), single: true
to_field VCARD['hasAddress'].to_s, lambda { |json, accum|
  address_json = JsonPath.on(json, '$.contacts[?(@["type"] == "academic")]').first
  if address_json
    accum << {
      '@id' => RIALTO_CONTEXT_ADDRESSES[json['profileId']],
      '@type' => VCARD['Address'],
      "!#{VCARD['street-address']}" => true,
      VCARD['street-address'].to_s => address_json['address'],
      "!#{VCARD['locality']}" => true,
      VCARD['locality'].to_s => address_json['city'],
      "!#{VCARD['region']}" => true,
      VCARD['region'].to_s => address_json['state'],
      "!#{VCARD['postal-code']}" => true,
      VCARD['postal-code'].to_s => address_json['zip'],
      # Punting on looking up country based on postal code (http://www.geonames.org/export/web-services.html) and
      # hardcoding to US (http://sws.geonames.org/6252001/)
      "!#{VCARD['country-name']}" => true,
      VCARD['country-name'].to_s => 'United States',
      "!#{DCTERMS['spatial']}" => true,
      DCTERMS['spatial'].to_s => RDF::URI.new('http://sws.geonames.org/6252001/')
    }
  end
}, single: true

# Note: There is also relatedBy for positions.
to_field VIVO['relatedBy'].to_s, lambda { |json, accum|
  advisees_json = JsonPath.on(json, '$.advisees[*].advisee')
  advisees = []
  advisees_json.each do |advisee_json|
    advisees << {
      '@id' => RIALTO_CONTEXT_RELATIONSHIPS["#{advisee_json['profileId']}_#{json['profileId']}"],
      '@type' => VIVO['AdvisingRelationship'],
      DCTERMS['valid'].to_s => Time.now.to_date
    }
  end
  accum.concat(advisees)
}

to_field OBO['RO_0000053'].to_s, lambda { |json, accum|
  unless JsonPath.on(json, '$.advisees').empty?
    accum << {
      '@id' => RIALTO_CONTEXT_ROLES['AdvisorRole'],
      '@type' => VIVO['AdvisorRole'],
      # This points back at the advisor
      OBO['RO_0000052'].to_s => RIALTO_PEOPLE[json['profileId']]
    }
  end
}

# rubocop:disable Metrics/BlockLength
to_field '#advisees', lambda { |json, accum|
  advisees_json = JsonPath.on(json, '$.advisees[*].advisee')
  advisees = []
  advisees_json.each do |advisee_json|
    full_name = "#{advisee_json['firstName']} #{advisee_json['lastName']}"
    advisees << {
      '@id' => RIALTO_PEOPLE[advisee_json['profileId']],
      '@type' => [FOAF['Agent'], FOAF['Person']],
      SKOS['prefLabel'].to_s => full_name,
      RDFS['label'].to_s => full_name,
      # Name VCard
      VCARD['hasName'].to_s => {
        '@id' => RIALTO_CONTEXT_NAMES[advisee_json['profileId']],
        '@type' => VCARD['Name'],
        "!#{VCARD['given-name']}" => true,
        VCARD['given-name'].to_s => advisee_json['firstName'],
        "!#{VCARD['family-name']}" => true,
        VCARD['family-name'].to_s => advisee_json['lastName']
      },
      # Related by
      VIVO['relatedBy'].to_s => RIALTO_CONTEXT_RELATIONSHIPS["#{advisee_json['profileId']}_#{json['profileId']}"],
      # Advisee role
      OBO['RO_0000053'].to_s => {
        '@id' => RIALTO_CONTEXT_ROLES['AdviseeRole'],
        '@type' => VIVO['AdviseeRole'],
        # This points back at the advisee
        OBO['RO_0000052'].to_s => RIALTO_PEOPLE[advisee_json['profileId']]
      }
    }
  end
  accum << advisees unless advisees.empty?
}, single: true
# rubocop:enable Metrics/BlockLength

# Email
to_field '!' + VCARD['hasEmail'].to_s, literal(true)
to_field VCARD['hasEmail'].to_s, extract_json('$.primaryContact.email'), single: true

# SUNet Id
to_field DCTERMS['identifier'].to_s, lambda { |json, accum|
  if (sunet_id = JsonPath.on(json, '$.uid').first)
    accum << RDF::Literal.new(sunet_id, datatype: RIALTO_CONTEXT_IDENTIFIERS['Sunetid'])
  end
}, single: true

# Person positions
to_field VIVO['relatedBy'].to_s, lambda { |json, accum|
  titles_json = JsonPath.on(json, '$.titles').first
  positions = []
  orgs_map = Traject::TranslationMap.new('stanford_org_codes_to_organizations')
  titles_json.each do |title_json|
    org_code = title_json['organization']['orgCode']
    positions << {
      '@id' => RIALTO_CONTEXT_POSITIONS["#{org_code}_#{json['profileId']}"],
      '@type' => VIVO['Position'],
      "!#{DCTERMS['valid']}" => true,
      DCTERMS['valid'].to_s => Time.now.to_date,
      VIVO['relates'].to_s => [RIALTO_PEOPLE[json['profileId']], {
        '@id' => RIALTO_ORGANIZATIONS[orgs_map[org_code]],
        VIVO['relatedBy'].to_s => RIALTO_CONTEXT_POSITIONS["#{org_code}_#{json['profileId']}"]
      }],
      "!#{VIVO['hrJobTitle']}" => true,
      VIVO['hrJobTitle'].to_s => title_json['title'],
      "!#{RDFS['label']}" => true,
      RDFS['label'].to_s => title_json['label']['text']
    }
  end
  accum.concat(positions)
}
