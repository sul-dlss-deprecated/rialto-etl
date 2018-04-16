# frozen_string_literal: true

module Rialto
  module Etl
    # Holds writers for use in Traject mappings
    module Writers
      # Write JSON records to a list. This writer conforms to Traject's
      # writer class interface, supporting #initialize, #put, and
      # #close
      class JsonListWriter
        # Traject settings object

        # Constructor
        def initialize(_); end

        # Append the hash representing a single mapped record to the
        # list of records held in memory
        #
        # @param context [Traject::Indexer::Context] a Traject context
        #   object containing the output of the mapping
        # @return [Array] a list of all records mapped
        def put(context)
          records << context.output_hash
        end

        # Print a JSON representation of the records
        def close
          $stdout.puts({ records: records }.to_json)
        end

        private

        def records
          @records ||= []
        end
      end
    end
  end
end
