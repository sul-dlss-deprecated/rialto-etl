# frozen_string_literal: true

require 'csv'
require 'fileutils'

module Rialto
  module Etl
    module CLI
      # Publications iterates over the people in the input file CSV and for each
      # calls three other commands:
      #   exe/extract call WebOfScience --firstname Russ --lastname Altman > altman.ndj
      #   exe/transform call WebOfScience -i altman.ndj > altman.sparql
      #   exe/load call Sparql -i altman.sparql
      class Publications < Thor
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
        option :offset,
               required: false,
               default: 0,
               type: :numeric,
               banner: 'OFFSET',
               desc: 'Number of records to offset',
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

        desc 'load', 'Load all publications for all researchers in the CSV file'
        def load
          FileUtils.mkdir_p(options[:dir])
          csv_path = options[:input_file]
          count = 0
          offset = options[:offset]
          CSV.foreach(csv_path, headers: true, header_converters: :symbol) do |row|
            count += 1
            next if offset > count
            handle_row(row, count)
          end
        end

        private

        def handle_row(row, count)
          profile_id = row[:profileid]
          puts "Retrieving publications for: #{profile_id} (row: #{count})"

          wos_file = retrieve_publications(row, profile_id)
          return if !File.exist?(wos_file) || File.empty?(wos_file)

          puts "Transforming publications for: #{profile_id} (row: #{count})"

          sparql_file = transform_publications(wos_file, profile_id)
          return if !File.exist?(sparql_file) || File.empty?(sparql_file)

          return if options[:skip_load]
          puts "Loading sparql for #{profile_id}: #{row[:uri]}"
          Rialto::Etl::Loaders::Sparql.new(input: sparql_file).load
        end

        def transform_publications(wos_file, profile_id)
          sparql_file = File.join(options[:dir], "#{profile_id}.sparql")
          if File.exist?(sparql_file) && !options[:force]
            say "file #{sparql_file} already exists, skipping. use -f to force overwrite"
            return sparql_file
          end
          Rialto::Etl::Transformer.new(
            input_stream: File.open(wos_file, 'r'),
            config_file_path: 'lib/rialto/etl/configs/wos_to_sparql_statements.rb',
            output_file_path: sparql_file
          ).transform
          sparql_file
        end

        # rubocop:disable Metrics/MethodLength
        def retrieve_publications(row, profile_id)
          wos_file = File.join(options[:dir], "#{profile_id}.ndj")
          if File.exist?(wos_file) && !options[:force]
            say "file #{wos_file} already exists, skipping. use -f to force overwrite"
            return wos_file
          end
          results = []
          Rialto::Etl::Extractors::WebOfScience.new(firstname: row[:first_name], lastname: row[:last_name]).each do |result|
            results << result
          end
          return wos_file if results.empty?
          File.open(wos_file, 'w') do |f|
            f.write(results.join("\n"))
          end
          wos_file
        end
        # rubocop:enable Metrics/MethodLength
      end
    end
  end
end
