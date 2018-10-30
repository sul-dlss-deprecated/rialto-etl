# frozen_string_literal: true

require 'rialto/etl/transformer'
require 'rialto/etl/organizations'

module Rialto
  module Etl
    module CLI
      # Runs a transform on a whole directory of files
      class TransformDirectory < Thor
        option :input_directory,
               required: true,
               banner: 'INPUT',
               desc: 'Name of directory with data to be transformed (REQUIRED)',
               aliases: '-i'
        option :output_directory,
               default: '.',
               banner: 'OUTPUT',
               desc: 'Name of directory to write transformed data to',
               aliases: '-o'

        desc 'call NAME', "Call named transformer (`#{@package_name} list` to see available names)"

        # Call a transformer by name for each file in the directory
        def call(name)
          begin
            config = configs.fetch(name)
          rescue KeyError
            warn "No '#{name}' transformer exists. Call '#{$PROGRAM_NAME} list' to see valid options."
            exit(1)
          end
          transform_all(config)
        end

        desc 'list', 'List callable configs'
        # List callable configs
        def list
          callable_transformers = configs.keys.sort
          say "Transformers supported: #{callable_transformers.join(', ')}"
        end

        private

        def transform_all(config)
          Dir.glob(File.join(input_directory, '*.json')) do |filename|
            stream = File.open(filename, 'r')
            output = File.join(output_directory, File.basename(filename, '.json') + '.sparql')
            Transformer.new(
              input_stream: stream,
              config_file_path: config,
              output_file_path: output
            ).transform
          end
        end

        def input_directory
          options.fetch(:input_directory)
        end

        def output_directory
          options.fetch(:output_directory)
        end

        def configs
          {
            'StanfordGrants' => 'lib/rialto/etl/configs/stanford_grants_to_sparql_statements.rb'
          }
        end
      end
    end
  end
end
