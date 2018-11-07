# frozen_string_literal: true

require 'csv'
require 'fileutils'
require 'time'

module Rialto
  module Etl
    module CLI
      # Superclass for iterating over the people in the input file CSV and performing extract, transform, and load.
      # rubocop: disable Metrics/ClassLength
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
        option :threads,
               default: 1,
               type: :numeric,
               banner: 'THREADS',
               desc: 'Number of threads',
               aliases: '-t'
        option :offset,
               default: 0,
               type: :numeric,
               banner: 'OFFSET',
               desc: 'Number of records to offset',
               aliases: '-n'

        desc 'load', 'Extract, load, and transform for all researchers in the CSV file'

        # rubocop:disable Metrics/MethodLength
        # rubocop:disable Metrics/AbcSize
        def load
          start = Time.now
          FileUtils.mkdir_p(input_directory)
          queue = Queue.new
          threads = Array.new(options[:threads]) { handle_row_thread(queue) }
          CSV.foreach(options[:input_file], headers: true, header_converters: :symbol).each_with_index do |row, count|
            if offset && count < offset - 1
              puts "Skipping #{count + 1}"
              next
            end
            queue.push([row, count + 1])
          end
          queue.close
          threads.each(&:join)
          puts "Completed in #{Time.now - start} seconds"
        end
        # rubocop:enable Metrics/MethodLength
        # rubocop:enable Metrics/AbcSize

        no_commands do
          def handle_row_thread(queue)
            Thread.new do
              until queue.empty? && queue.closed?
                begin
                  row, count = queue.pop(true)
                  handle_row(row, count)
                # rubocop:disable Lint/HandleExceptions
                rescue ThreadError
                  # Ignore it
                end
                # rubocop:enable Lint/HandleExceptions
              end
            end
          end

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

        def offset
          options.fetch(:offset)
        end

        def input_directory
          options.fetch(:input_directory)
        end

        def output_directory
          options.fetch(:output_directory)
        end

        def file_prefix
          raise NotImplementedError
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
          rescue StandardError
            say "Skipping #{extract_file} because an error occurred while extracting"
            return extract_file
          end

          File.open(extract_file, 'w') do |f|
            f.write(results.join("\n"))
          end
          extract_file
        end
        # rubocop:enable Metrics/MethodLength

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
      # rubocop:enable Metrics/ClassLength
    end
  end
end
