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
        private

        def file_prefix
          'wos'
        end

        def extractor_class
          'Rialto::Etl::Extractors::WebOfScience'
        end

        def extractor_args
          %w[first_name last_name]
        end

        def transformer_config
          'lib/rialto/etl/configs/wos_to_sparql_statements.rb'
        end
      end
    end
  end
end
