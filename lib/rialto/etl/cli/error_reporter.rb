# frozen_string_literal: true

require 'honeybadger'

module Rialto
  module Etl
    module CLI
      # Logs errors to STDERR and to Honeybadger
      class ErrorReporter
        # Set up Honeybadger through shared_configs
        # Required in config/honeybadger.yml:
        # logging:
        #   path: "<PATH TO LOG FILE>"

        # rubocop:disable Style/StderrPuts
        def self.log_exception(message)
          $stderr.puts message

          Honeybadger.notify(message)
        end
        # rubocop:enable Style/StderrPuts
      end
    end
  end
end
