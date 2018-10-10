# frozen_string_literal: true

require 'yell'
require 'active_support'
require 'active_support/core_ext/numeric/conversions'
require 'sparql'
require 'set'

module Rialto
  module Etl
    module Readers
      # Read SPARQL statements from a file. Statements may be on multiple
      # lines, but are semicolon delimited.
      # Extracts and yields subjects from the INSERT statements.
      # UTF-8 encoding is required.
      class SparqlSubjectReader
        include Enumerable

        attr_reader :settings, :input_stream, :subjects
        attr_accessor :insert_count

        def initialize(input_stream, settings)
          @settings = settings
          @input_stream = input_stream
          @insert_count = 0
          @subjects = Set.new
        end

        # Get the logger from the settings, or default to an effectively null logger
        def logger
          settings['logger'] ||= Yell.new(STDERR, level: 'gt.fatal') # null logger
        end

        # rubocop:disable Metrics/MethodLength
        # rubocop:disable Metrics/AbcSize
        def each
          return enum_for(:each) unless block_given?

          # + below makes the string mutable
          statement = +''
          input_stream.each_line do |line|
            statement << line
            next unless statement.end_with?(";\n")
            if statement.start_with?('INSERT')
              logger.info("Read #{insert_count.to_s(:delimited)} INSERT statements.") if ((@insert_count += 1) % 1000).zero?
              # Extract subjects
              sse = SPARQL.parse(statement, update: true)
              sse.operands[0].operands[0][0].patterns.each do |pattern|
                subject = pattern.subject.to_s
                yield subject unless subjects.add?(subject).nil?
              end
            end
            statement = +''
          end
        end
        # rubocop:enable Metrics/MethodLength
        # rubocop:enable Metrics/AbcSize
      end
    end
  end
end
