# frozen_string_literal: true

module Rialto
  module Etl
    module Readers
      # Read SPARQL statements from a file. Statements may be on multiple
      # lines, but are semicolon delimited.
      # UTF-8 encoding is required.
      class SparqlStatementReader
        include Enumerable

        def initialize(input_stream, settings)
          @settings = settings
          @input_stream = input_stream
        end

        # rubocop:disable Metrics/MethodLength
        def each
          # Not sure if this is necessay
          return enum_for(:each) unless block_given?

          statements = +''
          statement = +''
          @input_stream.each_line do |line|
            statement << line
            next unless statement.end_with?(";\n")
            statements << statement
            if statement.start_with?('INSERT')
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
