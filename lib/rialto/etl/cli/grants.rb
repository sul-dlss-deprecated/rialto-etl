# frozen_string_literal: true

require 'fileutils'
require 'parallel'

module Rialto
  module Etl
    module CLI
      # Grants iterates over the people in the input file JSON and for each
      # valid UID (SUNet ID) calls three other commands:
      #   exe/extract call Sera --sunetid username > username.json
      #   TODO: exe/transform call Sera -i username.json > username.sparql
      #   TODO: exe/load call Sparql -i username.sparql
      class Grants < Thor
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
        option :batch_size,
               required: false,
               default: 3,
               banner: 'BATCH_SIZE',
               desc: 'Size of batch for parallel processing',
               aliases: '-s'
        option :force,
               required: false,
               default: false,
               banner: 'FORCE',
               desc: 'Overwrite files that already exist',
               aliases: '-f'

        desc 'Load', 'Load all grants for all researchers in the file'
        # rubocop:disable Metrics/MethodLength
        # rubocop:disable Metrics/AbcSize
        def load
          FileUtils.mkdir_p(options[:dir])
          File.open(options[:input_file], 'r') do |f|
            f.each_line.lazy.each_slice(options[:batch_size].to_i) do |lines|
              batch_ids = lines.map { |line| JSON.parse(line)['sunetid'] }
              Parallel.map(batch_ids, in_processes: options[:batch_size].to_i) do |id|
                output_file = File.join(options[:dir], "#{id}.json")
                if File.exist?(output_file) && !options[:force]
                  say "file #{output_file} already exists, skipping. use -f to force overwrite"
                  next
                end
                extract_and_write(id, output_file)
              end
            end
          end
        end
        # rubocop:enable Metrics/AbcSize

        private

        def extract_and_write(id, output_file)
          say "extracting SeRA records for #{id}"
          results = []
          Rialto::Etl::Extractors::Sera.new(sunetid: id).each do |result|
            results << result
          end
          return if results.empty?
          File.open(output_file, 'w') do |f|
            f.write(results.join("\n"))
          end
        rescue StandardError => exception
          say "retrying request for #{id}, failed: #{exception.message}"
          retry
        end
      end
      # rubocop:enable Metrics/MethodLength
    end
  end
end
