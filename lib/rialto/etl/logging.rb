# frozen_string_literal: true

require 'rialto/etl/loaders/sparql'
require 'yell'

module Rialto
  module Etl
    # A module to hold a logger
    module Logging
      attr_writer :logger

      def logger
        @logger ||= Yell::Logger.new(:null).tap do |logger|
          # Everything to stderr
          logger.adapter :stderr
          # Warnings to file
          logger.adapter :datefile, 'warnings.log', level: [:warn]
        end
      end
    end
  end
end
