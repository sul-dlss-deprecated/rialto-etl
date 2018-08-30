# frozen_string_literal: true

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

        def initialize(input_stream, settings)
          @settings = settings
          @input_stream = input_stream
        end

        # rubocop:disable Metrics/MethodLength
        def each
          return enum_for(:each) unless block_given?

          # + below makes the string mutable
          statements = +''
          statement = +''
          input_stream.each_line do |line|
            statement << line
            next unless statement.end_with?(";\n")
            statements << statement
            if statement.start_with?('INSERT') || settings['sparql_statement_reader.by_statement']
              yield statements
              statements = +''
            end
            statement = +''
          end
        end
        # rubocop:enable Metrics/MethodLength
      end
    end
  end
end
