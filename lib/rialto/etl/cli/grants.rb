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

        # rubocop:disable Metrics/MethodLength
        def perform_extract(row)
          results = []
          if (sunetid = row[:sunetid])
            Rialto::Etl::Extractors::Sera.new(sunetid: sunetid).each do |result|
              results << result
            end
          end
          results
        rescue Rialto::Etl::Extractors::Sera::ConnectionError,
               SocketError,
               Faraday::TimeoutError,
               Faraday::ConnectionFailed => exception
          say "retrying #{id}, failed with #{exception.class}: #{exception.message}"
          retry
        rescue StandardError => exception
          say "aborting #{id}, failed with #{exception.class}: #{exception.message}"
        end
        # rubocop:enable Metrics/MethodLength

        def transformer_config
          'lib/rialto/etl/configs/stanford_grants_to_sparql_statements.rb'
        end
      end
    end
  end
end
