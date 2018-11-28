# frozen_string_literal: true

require 'csv'
require 'fileutils'
require 'parallel'

module Rialto
  module Etl
    module CLI
      # rubocop:disable Metrics/ClassLength

      # Grants iterates over the people in the input file CSV and for each
      # calls extract, transform, and load.
      class Grants < Thor
        option :input_file,
               required: true,
               banner: 'FILENAME',
               desc: 'Path to the CSV manifest with researchers to be loaded (REQUIRED)',
               aliases: '-i'
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
        option :skip_load,
               default: false,
               type: :boolean,
               banner: 'SKIP_LOAD',
               desc: 'Skip load step'
        option :batch_size,
               default: 1,
               type: :numeric,
               banner: 'BATCH_SIZE',
               desc: 'Size of batch for parallel processing',
               aliases: '-s'
        option :offset,
               default: 0,
               type: :numeric,
               banner: 'OFFSET',
               desc: 'Number of records to offset',
               aliases: '-n'

        desc 'load', 'Extract, load, and transform for all researchers in the CSV file'
        def load
          FileUtils.mkdir_p(input_directory)
          csv_path = options[:input_file]
          count = 0
          CSV.foreach(csv_path, headers: true, header_converters: :symbol).each_slice(batch_size) do |rows|
            count += rows.length
            next if offset > count + rows.length
            Parallel.each_with_index(rows, in_processes: rows.length) do |row, index|
              handle_row(row, count - batch_size + index + 1)
            end
          end
        end

        private

        no_commands do
          delegate :log_exception, to: ErrorReporter
        end

        # Performs ETL on a single row
        def handle_row(row, count)
          profile_id = row[:profileid]
          say "Extracting for #{profile_id} (row: #{count})"

          source_file = extract(row, profile_id, options[:force])
          return if !File.exist?(source_file) || File.empty?(source_file)

          say "Transforming for #{profile_id} (row: #{count})"

          sparql_file = transform(source_file, profile_id, options[:force])
          return if options[:skip_load] || !File.exist?(sparql_file) || File.empty?(sparql_file)

          say "Loading sparql for #{profile_id}: #{row[:uri]}"
          load_sparql(sparql_file)
        end

        # rubocop:disable Metrics/MethodLength
        def extract(row, profile_id, force)
          extract_file = File.join(input_directory, "#{file_prefix}-#{profile_id}.ndj")
          if File.exist?(extract_file) && !force
            say "file #{extract_file} already exists, skipping. use -f to force overwrite"
            return extract_file
          end
          # Don't write file if an exception occurs
          begin
            results = perform_extract(row)
          rescue StandardError => exception
            log_exception "Skipping #{extract_file} because an error occurred while extracting: " \
                          "#{exception.message} (#{exception.class})"
            FileUtils.rm(extract_file, force: true)
            return extract_file
          end

          File.open(extract_file, 'w') do |f|
            f.write(results.join("\n"))
          end
          extract_file
        end
        # rubocop:enable Metrics/MethodLength

        # rubocop:disable Metrics/MethodLength
        def transform(source_file, profile_id, force)
          sparql_file = File.join(output_directory, "#{file_prefix}-#{profile_id}.sparql")
          if File.exist?(sparql_file) && !force
            say "file #{sparql_file} already exists, skipping. use -f to force overwrite"
            return sparql_file
          end
          begin
            Rialto::Etl::Transformer.new(
              input_stream: File.open(source_file, 'r'),
              config_file_path: transformer_config,
              output_file_path: sparql_file
            ).transform
          rescue StandardError => exception
            log_exception "Skipping #{sparql_file} because an error occurred while transforming: "\
                          "#{exception.message} (#{exception.class})"
            FileUtils.rm(sparql_file, force: true)
            return sparql_file
          end
          sparql_file
        end
        # rubocop:enable Metrics/MethodLength

        def load_sparql(sparql_file)
          Rialto::Etl::Loaders::Sparql.new(input: sparql_file).load
        rescue StandardError => exception
          log_exception "An error occurred loading #{sparql_file} but continuing: "\
                        "#{exception.message} (#{exception.class})"
        end

        def perform_extract(row)
          results = []
          if (sunetid = row[:sunetid])
            Rialto::Etl::Extractors::Sera.new(sunetid: sunetid).each do |result|
              results << result
            end
          end
          results
        end

        def offset
          options.fetch(:offset)
        end

        def batch_size
          options.fetch(:batch_size).to_i
        end

        def input_directory
          options.fetch(:input_directory)
        end

        def output_directory
          options.fetch(:output_directory)
        end

        def file_prefix
          'sera'
        end

        def transformer_config
          'lib/rialto/etl/configs/stanford_grants_to_sparql_statements.rb'
        end
      end
      # rubocop:enable Metrics/ClassLength
    end
  end
end
