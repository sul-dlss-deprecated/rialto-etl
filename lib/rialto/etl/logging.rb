# frozen_string_literal: true

require 'yell'

module Rialto
  module Etl
    # A module to hold a logger
    module Logging
      attr_writer :logger

      def logger
        @logger ||= Yell.new do |logger|
          logger.adapter :datefile, info_log, level: 'lte.warn' # anything lower or equal to :warn
          logger.adapter :datefile, error_log, level: 'gte.error' # anything greater or equal to :error
        end
      end

      private

      def log_path
        Settings.log_path || './log/'
      end

      def info_log
        File.join(log_path, 'rialto_etl.log')
      end

      def error_log
        File.join(log_path, 'rialto_etl_error.log')
      end
    end
  end
end
