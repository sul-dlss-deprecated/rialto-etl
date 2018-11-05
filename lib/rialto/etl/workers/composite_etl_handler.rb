# frozen_string_literal: true

$LOAD_PATH.unshift 'lib'

require 'bundler/setup'
require 'rialto/etl'
require 'rialto/etl/loaders/sparql'
require 'rialto/etl/transformer'
require 'sidekiq'

module Rialto
  module Etl
    # Module to hold worker classes
    module Workers
      # Perform ETL on CSV rows in the background
      class CompositeEtlHandler
        include Sidekiq::Worker

        Sidekiq::Logging.logger.level = Logger::INFO

        attr_reader :row, :row_number, :file_prefix, :transformer_config, :options

        # rubocop:disable Metrics/ParameterLists
        # rubocop:disable Metrics/MethodLength
        def perform(row, row_number, file_prefix, transformer_config, extractor_class, extractor_args, options)
          @row = row
          @row_number = row_number
          @file_prefix = file_prefix
          @transformer_config = transformer_config
          @extractor_class = extractor_class
          @extractor_args = extractor_args
          @options = options

          source_file = extract
          return if !File.exist?(source_file) || File.empty?(source_file)

          sparql_file = transform(source_file)
          return if options['skip_load'] || !File.exist?(sparql_file) || File.empty?(sparql_file)

          load(sparql_file)
        end
        # rubocop:enable Metrics/MethodLength
        # rubocop:enable Metrics/ParameterLists

        private

        # Pass the extractor class to the worker as a string (Sidekiq requirement)
        def extractor_class
          Kernel.const_get(@extractor_class)
        end

        # Pass the args for the extractor as an array to the worker, e.g.:
        # Turns ['one', 'two', 'three'] into { one: row['one'], two: row['two'], three: ['three'] }
        # Assumes arg names match row field names
        def extractor_args
          keyword_hash = {}
          @extractor_args.each do |arg|
            keyword_hash[arg.to_sym] = row[arg]
          end
          keyword_hash
        end

        def extract
          extract_file = File.join(input_directory, "#{file_prefix}-#{profile_id}.ndj")
          return extract_file if options['skip_extract']
          logger.info "Extracting for #{profile_id} (row: #{row_number})"
          if File.exist?(extract_file) && !force?
            logger.warn "file #{extract_file} already exists, skipping. use -f to force overwrite"
            return extract_file
          end
          results = perform_extract
          File.open(extract_file, 'w') { |f| f.write(results.join("\n")) }
          extract_file
        end

        def perform_extract
          results = []
          extractor_class.new(extractor_args).each do |result|
            results << result
          end
          results
        end

        def transform(source_file)
          sparql_file = File.join(output_directory, "#{file_prefix}-#{profile_id}.sparql")
          if File.exist?(sparql_file) && !force?
            logger.warn "file #{sparql_file} already exists, skipping. use -f to force overwrite"
            return sparql_file
          end
          logger.info "Transforming for #{profile_id} (row: #{row_number})"
          Rialto::Etl::Transformer.new(input_stream: File.open(source_file, 'r'),
                                       config_file_path: transformer_config,
                                       output_file_path: sparql_file).transform
          sparql_file
        end

        def load(sparql_file)
          logger.info "Loading sparql for #{profile_id}: #{row['uri']}"
          Rialto::Etl::Loaders::Sparql.new(input: sparql_file).load
        end

        def force?
          options['force']
        end

        def input_directory
          options.fetch('input_directory')
        end

        def output_directory
          options.fetch('output_directory')
        end

        def profile_id
          row['profileid']
        end
      end
    end
  end
end
