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
        private

        def file_prefix
          'sera'
        end

        def extractor_class
          'Rialto::Etl::Extractors::Sera'
        end

        def extractor_args
          ['sunetid']
        end

        def transformer_config
          'lib/rialto/etl/configs/stanford_grants_to_sparql_statements.rb'
        end
      end
    end
  end
end
