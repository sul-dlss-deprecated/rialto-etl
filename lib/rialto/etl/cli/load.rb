# frozen_string_literal: true

require 'rialto/etl/loaders'
require 'rialto/etl/logging'

module Rialto
  module Etl
    module CLI
      # Load subcommand
      class Load < Thor
        include Rialto::Etl::Logging

        option :input_file,
               required: true,
               banner: 'FILENAME',
               desc: 'Name of file with data to be loaded (REQUIRED)',
               aliases: '-i'

        desc 'call NAME', "Call named loader (`#{@package_name} list` to see available names)"
        # Call a loader by name
        def call(name)
          Dir["#{options[:input_file]}/*"].each do |file|
            next if File.directory? file
            say "Loading sparql file: #{file}"
            Rialto::Etl::Loaders.const_get(name).new(input: file).load
          end

          Rialto::Etl::Loaders.const_get(name).new(input: options[:input_file]).load
        end

        desc 'list', 'List callable loaders'
        # List callable loaders
        def list
          callable_loaders = Rialto::Etl::Loaders.constants
          say "Loaders supported: #{callable_loaders.join(', ')}"
        end
      end
    end
  end
end
