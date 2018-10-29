# frozen_string_literal: true

require 'csv'
require 'fileutils'
require 'rialto/etl/cli/composite_etl'

module Rialto
  module Etl
    module CLI
      # Grants iterates over the people in the input file CSV and for each
      # calls extract, transform, and load.
      class Grants < CompositeEtl
        protected

        def file_prefix
          'sera'
        end

        def perform_extract(row)
          results = []
          if (sunetid = row[:sunetid])
            Rialto::Etl::Extractors::Sera.new(sunetid: sunetid).each do |result|
              results << result
            end
          end
          results
        rescue StandardError => exception
          say "aborting #{sunetid}, failed with #{exception.class}: #{exception.message}"
        end

        def transformer_config
          'lib/rialto/etl/configs/stanford_grants_to_sparql_statements.rb'
        end
      end
    end
  end
end
