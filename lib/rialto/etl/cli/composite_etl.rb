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
               desc: 'Name of file with data to be loaded (REQUIRED)',
               aliases: '-i'
        option :dir,
               required: false,
               default: 'data',
               banner: 'DIR',
               desc: 'Name of the directory to store data in',
               aliases: '-d'
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

        # rubocop:disable Metrics/MethodLength
        def load
          FileUtils.mkdir_p(options[:dir])
          csv_path = options[:input_file]
          count = 0
          CSV.foreach(csv_path, headers: true, header_converters: :symbol).each_slice(options[:batch_size].to_i) do |rows|
            begin
              Parallel.each_with_index(rows, in_processes: rows.length) do |row, index|
                handle_row(profile_id: row.fetch(:profileid), uri: row.fetch(:uri), count: count + index + 1)
              end
              count += rows.length
            rescue TypeError => exception
              sleep(90)
              say "Unable to write to pipe, retrying after 90 seconds: #{exception.message}"
              retry
            end
          end
        end
        # rubocop:enable Metrics/MethodLength

        no_commands do
          # Performs ETL on a single row
          def handle_row(profile_id:, uri:, count:)
            puts "Extracting for #{profile_id} (row: #{count})"

            source_file = extract(row, profile_id, options[:force])
            return if !File.exist?(source_file) || File.empty?(source_file)

            puts "Transforming for #{profile_id} (row: #{count})"

            sparql_file = transform(source_file, profile_id, options[:force])
            return if options[:skip_load] || !File.exist?(sparql_file) || File.empty?(sparql_file)

            puts "Loading sparql for #{profile_id}: #{uri}"
            Rialto::Etl::Loaders::Sparql.new(input: sparql_file).load
          end
        end

        protected

        def file_prefix
          raise NotImplementedError
        end

        def extract(row, profile_id, force)
          extract_file = File.join(options[:dir], "#{file_prefix}-#{profile_id}.ndj")
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
          sparql_file = File.join(options[:dir], "#{file_prefix}-#{profile_id}.sparql")
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
