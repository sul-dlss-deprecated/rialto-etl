# frozen_string_literal: true

require 'honeybadger/ruby'

module Rialto
  module Etl
    module CLI
      # Logs errors to STDERR and to Honeybadger
      class ErrorReporter
        extend Logging

        # Set up Honeybadger manually, so that we set the logger before honeybadger
        # logs its first message.
        Honeybadger.init!(framework: :ruby, env: ENV['RUBY_ENV'])
        Honeybadger.load_plugins!
        Honeybadger.install_at_exit_callback
        Honeybadger.configure do |config|
          config.logger = logger
        end

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
