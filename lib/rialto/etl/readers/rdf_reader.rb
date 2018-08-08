# frozen_string_literal: true

module Rialto
  module Etl
    module Readers
      # Reads in RDF statements
      class RDFReader
        # @param reader [RDF::Reader]
        # @param settings [Traject::Indexer::Settings]
        def initialize(reader, settings)
          @rdf = reader
          @settings = Traject::Indexer::Settings.new settings
        end

        attr_reader :rdf

        # Yields an RDF::Statement to the given block
        def each(&block)
          return to_enum(:each) unless block_given?
          rdf.each_statement(&block)
        end
      end
    end
  end
end
