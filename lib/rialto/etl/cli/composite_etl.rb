# frozen_string_literal: true

require 'csv'
require 'fileutils'
require 'parallel'

module Rialto
  module Etl
    module CLI
      # Superclass for iterating over the people in the input file CSV and performing extract, transform, and load.
      class CompositeEtl < Thor
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
               required: false,
               default: false,
               type: :boolean,
               banner: 'FORCE',
               desc: 'Overwrite files that already exist',
               aliases: '-f'
        option :skip_load,
               required: false,
               default: false,
               type: :boolean,
               banner: 'SKIP_LOAD',
               desc: 'Skip load step'
        option :batch_size,
               required: false,
               default: 1,
               type: :numeric,
               banner: 'BATCH_SIZE',
               desc: 'Size of batch for parallel processing',
               aliases: '-s'
        desc 'load', 'Extract, load, and transform for all researchers in the CSV file'

        def load
          FileUtils.mkdir_p(input_directory)
          csv_path = options[:input_file]
          count = 0
          CSV.foreach(csv_path, headers: true, header_converters: :symbol).each_slice(options[:batch_size].to_i) do |rows|
            Parallel.each_with_index(rows, in_processes: rows.length) do |row, index|
              handle_row(row, count + index + 1)
            end
            count += rows.length
          end
        end

        no_commands do
          # rubocop:disable Metrics/AbcSize
          # Performs ETL on a single row
          def handle_row(row, count)
            profile_id = row[:profileid]
            puts "Extracting for #{profile_id} (row: #{count})"

            source_file = extract(row, profile_id, options[:force])
            return if !File.exist?(source_file) || File.empty?(source_file)

            puts "Transforming for #{profile_id} (row: #{count})"

            sparql_file = transform(source_file, profile_id, options[:force])
            return if options[:skip_load] || !File.exist?(sparql_file) || File.empty?(sparql_file)

            puts "Loading sparql for #{profile_id}: #{row[:uri]}"
            Rialto::Etl::Loaders::Sparql.new(input: sparql_file).load
          end
          # rubocop:enable Metrics/AbcSize
        end

        protected

        def input_directory
          options.fetch(:input_directory)
        end

        def output_directory
          options.fetch(:output_directory)
        end

        def file_prefix
          raise NotImplementedError
        end

        def extract(row, profile_id, force)
          extract_file = File.join(input_directory, "#{file_prefix}-#{profile_id}.ndj")
          if File.exist?(extract_file) && !force
            say "file #{extract_file} already exists, skipping. use -f to force overwrite"
            return extract_file
          end
          results = perform_extract(row)
          File.open(extract_file, 'w') do |f|
            f.write(results.join("\n"))
          end
          extract_file
        end

        def perform_extract(_row)
          raise NotImplementedError
        end

        def transform(source_file, profile_id, force)
          sparql_file = File.join(output_directory, "#{file_prefix}-#{profile_id}.sparql")
          if File.exist?(sparql_file) && !force
            say "file #{sparql_file} already exists, skipping. use -f to force overwrite"
            return sparql_file
          end
          Rialto::Etl::Transformer.new(
            input_stream: File.open(source_file, 'r'),
            config_file_path: transformer_config,
            output_file_path: sparql_file
          ).transform
          sparql_file
        end

        def transformer_config
          raise NotImplementedError
        end
      end
    end
  end
end
