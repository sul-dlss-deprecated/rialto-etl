# frozen_string_literal: true

require 'rialto/etl/loaders/sparql'
require 'yell'

module Rialto
  module Etl
    # A module to hold a logger
    module Logging
      attr_writer :logger

      def logger
        @logger ||= Yell.new do |logger|
          logger.adapter :datefile, 'rialto_etl.log', level: 'lte.warn' # anything lower or equal to :warn
          logger.adapter :datefile, 'rialto_etl_error.log', level: 'gte.error' # anything greater or equal to :error
        end
      end
    end
  end
end
