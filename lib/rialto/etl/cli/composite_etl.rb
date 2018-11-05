# frozen_string_literal: true

require 'csv'
require 'fileutils'
require 'parallel'
require 'rialto/etl/workers/composite_etl_handler'

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
        option :skip_extract,
               default: false,
               type: :boolean,
               banner: 'SKIP_EXTRACT',
               desc: 'Skip extract step'
        option :batch_size,
               default: 1,
               type: :numeric,
               banner: 'BATCH_SIZE',
               desc: 'Size of batches to read (CSV rows)',
               aliases: '-s'
        option :offset,
               default: 0,
               type: :numeric,
               banner: 'OFFSET',
               desc: 'Number of records to offset',
               aliases: '-n'

        # rubocop:disable Metrics/AbcSize
        # rubocop:disable Metrics/MethodLength
        desc 'load', 'Extract, load, and transform for all researchers in the CSV file'
        def load
          FileUtils.mkdir_p(options[:input_directory])
          csv_path = options[:input_file]
          count = 0
          CSV.foreach(csv_path, headers: true, header_converters: :symbol).each_slice(batch_size) do |rows|
            count += rows.length
            next if offset > count + rows.length
            rows.each_with_index do |row, index|
              row_number = count - batch_size + index + 1
              # Coerce row to hash because sidekiq requires literals as args
              Rialto::Etl::Workers::CompositeEtlHandler
                .perform_async(row.to_hash, row_number, file_prefix, transformer_config, extractor_class, extractor_args, options)
            end
          end
        end
        # rubocop:enable Metrics/MethodLength
        # rubocop:enable Metrics/AbcSize

        private

        def offset
          options.fetch(:offset)
        end

        def batch_size
          options.fetch(:batch_size).to_i
        end

        def file_prefix
          raise NotImplementedError
        end

        def perform_extract(_row)
          raise NotImplementedError
        end

        def transformer_config
          raise NotImplementedError
        end
      end
    end
  end
end
