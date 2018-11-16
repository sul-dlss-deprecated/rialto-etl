# frozen_string_literal: true

require 'fileutils'
require 'jsonpath'

module Rialto
  module Etl
    module CLI
      # Publications grabs all Stanford University-affiliated publications from
      # the WoS API, then transforms and loads them.
      class Publications < Thor
        option :input_directory,
               default: 'data',
               banner: 'INPUT',
               desc: 'Name of directory with data to be transformed',
               aliases: '-d'
        option :output_directory,
               default: 'data',
               banner: 'OUTPUT',
               desc: 'Name of directory to write transformed data to',
               aliases: '-o'
        option :force,
               default: false,
               type: :boolean,
               banner: 'FORCE',
               desc: 'Overwrite files that already exist',
               aliases: '-f'
        option :skip_extract,
               default: false,
               type: :boolean,
               banner: 'SKIP_EXTRACT',
               desc: 'Skip extract step'
        option :skip_load,
               default: false,
               type: :boolean,
               banner: 'SKIP_LOAD',
               desc: 'Skip load step'

        desc 'load', 'Extract, load, and transform for all Stanford University publications in WoS'
        def load
          FileUtils.mkdir_p(input_directory)

          extract do |source_file|
            sparql_file = transform(source_file)

            load_sparql(sparql_file)
          end
        end

        private

        def cached_files(&_block)
          Dir.glob("#{input_directory}/WOS*.json").each { |file_path| yield file_path }
        end

        # rubocop:disable Metrics/MethodLength
        def extract(&block)
          return cached_files(&block) if options[:skip_extract]
          Rialto::Etl::Extractors::WebOfScience.new.each do |record_list|
            JSON.parse(record_list).each do |record|
              extract_file = File.join(input_directory, "#{record['UID']}.json")

              if File.exist?(extract_file) && !options[:force]
                say "file #{extract_file} already exists, skipping. use -f to force overwrite"
              else
                File.open(extract_file, 'w') { |f| f.write(record.to_json) }
              end

              yield extract_file
            end
          end
        end
        # rubocop:enable Metrics/MethodLength

        # rubocop:disable Metrics/MethodLength
        def transform(source_file)
          basename = File.basename(source_file, '.json')
          sparql_file = File.join(output_directory, "#{basename}.sparql")
          if File.exist?(sparql_file) && !options[:force]
            say "file #{sparql_file} already exists, skipping. use -f to force overwrite"
            return sparql_file
          end
          say "Transforming #{source_file}"
          begin
            Rialto::Etl::Transformer.new(
              input_stream: File.open(source_file, 'r'),
              config_file_path: transformer_config,
              output_file_path: sparql_file
            ).transform
          rescue StandardError => exception
            say "Skipping #{sparql_file} because an error occurred while transforming: #{exception.message} (#{exception.class})"
            FileUtils.rm(sparql_file, force: true)
          end
          sparql_file
        end
        # rubocop:enable Metrics/MethodLength

        def load_sparql(sparql_file)
          return if options[:skip_load] || !File.exist?(sparql_file) || File.empty?(sparql_file)
          say "Loading sparql from #{sparql_file}"
          Rialto::Etl::Loaders::Sparql.new(input: sparql_file).load
        rescue StandardError => exception
          say "An error occurred loading #{sparql_file} but continuing: #{exception.message} (#{exception.class})"
        end

        def input_directory
          options.fetch(:input_directory)
        end

        def output_directory
          options.fetch(:output_directory)
        end

        def transformer_config
          'lib/rialto/etl/configs/wos_to_sparql_statements.rb'
        end
      end
    end
  end
end
