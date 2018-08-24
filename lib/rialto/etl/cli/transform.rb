# frozen_string_literal: true

require 'rialto/etl/transformers'

module Rialto
  module Etl
    module CLI
      # Transform subcommand
      class Transform < Thor
        option :input_file,
               required: true,
               banner: 'FILENAME',
               desc: 'Name of file with data to be transformed (REQUIRED)',
               aliases: '-i'
        desc 'call NAME', "Call named transformer (`#{@package_name} list` to see available names)"
        # Call a transformer by name
        def call(name)
          begin
            klass = Rialto::Etl::Transformers.const_get(name)
          rescue NameError
            warn "No '#{name}' transformer exists. Call '#{$PROGRAM_NAME} list' to see valid options."
            exit(1)
          end
          klass.new(input: options[:input_file]).transform
        end

        desc 'list', 'List callable transformers'
        # List callable transformers
        def list
          callable_transformers = Rialto::Etl::Transformers.constants.map(&:to_s).sort
          say "Transformers supported: #{callable_transformers.join(', ')}"
        end
      end
    end
  end
end
