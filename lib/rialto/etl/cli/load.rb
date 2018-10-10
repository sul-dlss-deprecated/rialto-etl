# frozen_string_literal: true

require 'rialto/etl/loaders'

module Rialto
  module Etl
    module CLI
      # Load subcommand
      class Load < Thor
        option :input_file,
               required: true,
               banner: 'FILENAME',
               desc: 'Name of file with data to be loaded (REQUIRED)',
               aliases: '-i'

        desc 'call NAME', "Call named loader (`#{@package_name} list` to see available names)"
        # Call a loader by name
        def call(name)
          Rialto::Etl::Loaders.const_get(name).new(input: options[:input_file]).load
        end

        desc 'list', 'List callable loaders'
        # List callable loaders
        def list
          callable_loaders = Rialto::Etl::Loaders.constants
          say "Loaders supported: #{callable_loaders.sort.join(', ')}"
        end
      end
    end
  end
end
