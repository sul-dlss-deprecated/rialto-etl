# frozen_string_literal: true

require 'rdf'
require 'rdf/vocab'

module Rialto
  module Etl
    # Holds vocabs
    module Vocabs
      # Remove a vocab URI from a URI
      def remove_vocab_from_uri(vocab, uri)
        uri.to_s.delete_prefix(vocab.to_s)
      end
      rialto_base = 'http://sul.stanford.edu/rialto/'
      RIALTO_ORGANIZATIONS = RDF::Vocabulary.new(rialto_base + 'agents/orgs/')
      RIALTO_PEOPLE = RDF::Vocabulary.new(rialto_base + 'agents/people/')
      RIALTO_GRANTS = RDF::Vocabulary.new(rialto_base + 'grants/')
      RIALTO_PUBLICATIONS = RDF::Vocabulary.new(rialto_base + 'publications/')
      RIALTO_CONCEPTS = RDF::Vocabulary.new(rialto_base + 'concepts/')
      RIALTO_CONTEXT_NAMES = RDF::Vocabulary.new(rialto_base + 'context/names/')
      RIALTO_CONTEXT_ADDRESSES = RDF::Vocabulary.new(rialto_base + 'context/addresses/')
      RIALTO_CONTEXT_RELATIONSHIPS = RDF::Vocabulary.new(rialto_base + 'context/relationships/')
      RIALTO_CONTEXT_ROLES = RDF::Vocabulary.new(rialto_base + 'context/roles/')
      RIALTO_CONTEXT_IDENTIFIERS = RDF::Vocabulary.new(rialto_base + 'context/identifiers/')
      RIALTO_CONTEXT_POSITIONS = RDF::Vocabulary.new(rialto_base + 'context/positions/')

      # Local ontology
      class Stanford < RDF::StrictVocabulary(rialto_base + 'ontology#')
        term :PhdStudent
        term :MsStudent
        term :MdStudent
        term :Faculty
        term :Fellow
        term :Resident
        term :Postdoc
        term :Physician
        term :Staff
      end

      # The VIVO ontology
      class VIVO < RDF::StrictVocabulary('http://vivoweb.org/ontology/core#')
        term :AdviseeRole
        term :AdvisingRelationship
        term :AdvisorRole
        term :Authorship
        term :Department
        term :Division
        term :Editorship
        term :Grant
        term :Institute
        term :Position
        term :PrincipalInvestigatorRole
        term :School
        term :University

        property :assignedBy
        property :hasFundingVehicle
        property :hrJobTitle
        property :informationResourceSupportedBy
        property :overview
        property :publisher
        property :relates
        property :relatedBy
      end

      # Basic Formal Ontology designed for use in supporting information retrieval,
      # analysis and integration in scientific and other domains
      class OBO < RDF::StrictVocabulary('http://purl.obolibrary.org/obo/')
        property :BFO_0000050
        property :RO_0000052
        property :RO_0000053
      end

      # FRAPO, the Funding, Research Administration and Projects Ontology
      class FRAPO < RDF::StrictVocabulary('http://purl.org/cerif/frapo/')
        property :hasStartDate
        property :hasEndDate
      end

      SWS_GEONAMES = RDF::Vocabulary.new('http://sws.geonames.org/')
    end
    # Holds graph names
    module NamedGraphs
      rialto_base = 'http://sul.stanford.edu/rialto/graphs/'
      STANFORD_PEOPLE_GRAPH = RDF::URI.new(rialto_base + 'stanford_people')
      STANFORD_ORGANIZATIONS_GRAPH = RDF::URI.new(rialto_base + 'stanford_organizations')
      WOS_GRAPH = RDF::URI.new(rialto_base + 'wos')
      STANFORD_GRANTS_GRAPH = RDF::URI.new(rialto_base + 'stanford_grants')
    end
  end
end
