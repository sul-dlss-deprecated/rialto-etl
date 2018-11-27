# frozen_string_literal: true

require 'honeybadger'

module Rialto
  module Etl
    module CLI
      # Logs errors to STDERR and to Honeybadger
      class ErrorReporter
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
