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

        def each
          # Not sure if this is necessay
          return enum_for(:each) unless block_given?

          statements = +''
          statement = +''
          @input_stream.each_line do |line|
            statement << line
            if statement.end_with?(";\n")
              statements << statement
              if statement.start_with?('INSERT')
                yield statements
                statements = +''
              end
              statement = +''
            end
          end
        end
      end
    end
  end
end
