# frozen_string_literal: true

require 'csv'
require 'fileutils'
require 'rialto/etl/cli/composite_etl'

module Rialto
  module Etl
    module CLI
      # Publications iterates over the people in the input file CSV and for each
      # calls extract, transform, and load.
      class Publications < CompositeEtl
        protected

        def file_prefix
          'wos'
        end

        def perform_extract(row)
          results = []
          Rialto::Etl::Extractors::WebOfScience.new(firstname: row[:first_name], lastname: row[:last_name]).each do |result|
            results << result
          end
          results
        end

        def transformer_config
          'lib/rialto/etl/configs/wos_to_sparql_statements.rb'
        end
      end
    end
  end
end
