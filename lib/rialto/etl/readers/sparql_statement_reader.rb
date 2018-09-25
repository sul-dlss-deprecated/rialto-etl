# frozen_string_literal: true

require 'yell'
require 'active_support'
require 'active_support/core_ext/numeric/conversions'

module Rialto
  module Etl
    module Readers
      # Read SPARQL statements from a file. Statements may be on multiple
      # lines, but are semicolon delimited.
      # DELETES are grouped with any following INSERTS. This is to avoid concurrency problems when executing in parallel.
      # UTF-8 encoding is required.
      class SparqlStatementReader
        include Enumerable

        attr_reader :settings, :input_stream
        attr_accessor :insert_count

        def initialize(input_stream, settings)
          @settings = settings
          @input_stream = input_stream
          @insert_count = 0
        end

        # Get the logger from the settings, or default to an effectively null logger
        def logger
          settings['logger'] ||= Yell.new(STDERR, level: 'gt.fatal') # null logger
        end

        # rubocop:disable Metrics/MethodLength
        # rubocop:disable Metrics/AbcSize
        # rubocop:disable Metrics/CyclomaticComplexity
        def each
          return enum_for(:each) unless block_given?

          # + below makes the string mutable
          statements = +''
          statement = +''
          input_stream.each_line do |line|
            statement << line
            next unless statement.end_with?(";\n")
            statements << statement
            logger.info("Read #{insert_count.to_s(:delimited)} INSERT statements.") if statement.start_with?('INSERT') &&
                                                                                       ((@insert_count += 1) % 1000).zero?
            if statement.start_with?('INSERT') || settings['sparql_statement_reader.by_statement']
              yield statements
              statements = +''
            end
            statement = +''
          end
        end
        # rubocop:enable Metrics/MethodLength
        # rubocop:enable Metrics/AbcSize
        # rubocop:enable Metrics/CyclomaticComplexity
      end
    end
  end
end
