# frozen_string_literal: true

require 'rdf/vocabulary'
require 'rdf'

module Rialto
  module Etl
    # Holds vocabs
    module Vocabs
      rialto_base = 'http://sul.stanford.edu/rialto/'
      RIALTO_ORGANIZATIONS = RDF::Vocabulary.new(rialto_base + 'agents/orgs/')
      RIALTO_PEOPLE = RDF::Vocabulary.new(rialto_base + 'agents/people/')
      RIALTO_CONTEXT_NAMES = RDF::Vocabulary.new(rialto_base + 'context/names/')
      RIALTO_CONTEXT_ADDRESSES = RDF::Vocabulary.new(rialto_base + 'context/addresses/')
      RIALTO_CONTEXT_RELATIONSHIPS = RDF::Vocabulary.new(rialto_base + 'context/relationships/')
      RIALTO_CONTEXT_ROLES = RDF::Vocabulary.new(rialto_base + 'context/roles/')
      SKOS = RDF::Vocabulary.new('http://www.w3.org/2004/02/skos/core#')
      VCARD = RDF::Vocabulary.new('http://www.w3.org/2006/vcard/ns#')
      FOAF = RDF::Vocabulary.new('http://xmlns.com/foaf/0.1/')
      VIVO = RDF::Vocabulary.new('http://vivoweb.org/ontology/core#')
      DCTERMS = RDF::Vocabulary.new('http://purl.org/dc/terms/')
      OBO = RDF::Vocabulary.new('http://purl.obolibrary.org/obo/')
    end
    # Holds graph names
    module NamedGraphs
      rialto_base = 'http://sul.stanford.edu/rialto/graphs/'
      STANFORD_PEOPLE_GRAPH = RDF::URI.new(rialto_base + 'stanford_people')
      STANFORD_ORGANIZATIONS_GRAPH = RDF::URI.new(rialto_base + 'stanford_organizations')
    end
  end
end
