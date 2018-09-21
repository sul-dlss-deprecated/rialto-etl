# frozen_string_literal: true

require 'rdf'

module Rialto
  module Etl
    # Holds vocabs
    module Vocabs
      rialto_base = 'http://sul.stanford.edu/rialto/'
      RIALTO_ORGANIZATIONS = RDF::Vocabulary.new(rialto_base + 'agents/orgs/')
      RIALTO_PEOPLE = RDF::Vocabulary.new(rialto_base + 'agents/people/')
      RIALTO_PUBLICATIONS = RDF::Vocabulary.new(rialto_base + 'publications/')
      RIALTO_CONCEPTS = RDF::Vocabulary.new(rialto_base + 'concepts/')
      RIALTO_CONTEXT_NAMES = RDF::Vocabulary.new(rialto_base + 'context/names/')
      RIALTO_CONTEXT_ADDRESSES = RDF::Vocabulary.new(rialto_base + 'context/addresses/')
      RIALTO_CONTEXT_RELATIONSHIPS = RDF::Vocabulary.new(rialto_base + 'context/relationships/')
      RIALTO_CONTEXT_ROLES = RDF::Vocabulary.new(rialto_base + 'context/roles/')
      RIALTO_CONTEXT_IDENTIFIERS = RDF::Vocabulary.new(rialto_base + 'context/identifiers/')
      RIALTO_CONTEXT_POSITIONS = RDF::Vocabulary.new(rialto_base + 'context/positions/')
      SKOS = RDF::Vocabulary.new('http://www.w3.org/2004/02/skos/core#')
      VCARD = RDF::Vocabulary.new('http://www.w3.org/2006/vcard/ns#')
      FOAF = RDF::Vocabulary.new('http://xmlns.com/foaf/0.1/')
      VIVO = RDF::Vocabulary.new('http://vivoweb.org/ontology/core#')
      DCTERMS = RDF::Vocabulary.new('http://purl.org/dc/terms/')
      OBO = RDF::Vocabulary.new('http://purl.obolibrary.org/obo/')
      RDFS = RDF::Vocabulary.new('http://www.w3.org/2000/01/rdf-schema#')
      BIBO = RDF::Vocabulary.new('http://purl.org/ontology/bibo/')
    end
    # Holds graph names
    module NamedGraphs
      rialto_base = 'http://sul.stanford.edu/rialto/graphs/'
      STANFORD_PEOPLE_GRAPH = RDF::URI.new(rialto_base + 'stanford_people')
      STANFORD_ORGANIZATIONS_GRAPH = RDF::URI.new(rialto_base + 'stanford_organizations')
      WOS_GRAPH = RDF::URI.new(rialto_base + 'wos')
    end
  end
end
