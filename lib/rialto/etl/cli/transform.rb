# frozen_string_literal: true

require 'rialto/etl/transformer'

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
            config = configs.fetch(name)
          rescue KeyError
            warn "No '#{name}' transformer exists. Call '#{$PROGRAM_NAME} list' to see valid options."
            exit(1)
          end
          Transformer.new(input_stream: stream, config_file_path: config).transform
        end

        desc 'list', 'List callable configs'
        # List callable configs
        def list
          callable_transformers = configs.keys.sort
          say "Transformers supported: #{callable_transformers.join(', ')}"
        end

        private

        def configs
          {
            'StanfordPeople' => 'lib/rialto/etl/configs/stanford_people_to_sparql_statements.rb',
            'StanfordPeopleList' => 'lib/rialto/etl/configs/stanford_people_to_list.rb',
            'StanfordOrganizations' => 'lib/rialto/etl/configs/stanford_organizations_to_sparql_statements.rb',
            'WebOfScience' => 'lib/rialto/etl/configs/wos_to_sparql_statements.rb'
          }
        end

        def stream
          File.open(options.fetch(:input_file), 'r')
        end
      end
    end
  end
end
