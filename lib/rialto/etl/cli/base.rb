# frozen_string_literal: true

module Rialto
  module Etl
    module CLI
      # Base class for command-line interface, dispatching to subcommands
      class Base < Thor
        package_name 'etl'

        def self.exit_on_failure?
          true
        end

        desc 'extract', "Extract subcommand (`#{@package_name} extract help` to learn more)"
        subcommand 'extract', Extract

        desc 'transform', "Transform subcommand (`#{@package_name} transform help` to learn more)"
        subcommand 'transform', Transform
      end
    end
  end
end
