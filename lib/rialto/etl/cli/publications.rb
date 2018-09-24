# frozen_string_literal: true

require 'csv'
require 'fileutils'

module Rialto
  module Etl
    module CLI
      # Publications iterates over the people in the input file CSV and for each
      # calls three other commands:
      #   exe/extract call WebOfScience --firstname Russ --lastname Altman > altman.ndj
      #   exe/transform call WebOfScience -i altman.ndj > altman.jsonld
      #   exe/load call Sparql -i altman.jsonld
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
               default: 0,
               type: :numeric,
               required: false,
               banner: 'OFFSET',
               desc: 'Number of records to offset',
               aliases: '-o'

        desc 'load', 'Load all publications for all researchers in the file'
        def load
          FileUtils.mkdir_p(options[:dir])
          csv_path = options[:input_file]
          count = 0
          offset = options[:offset]
          CSV.foreach(csv_path, headers: true, header_converters: :symbol) do |row|
            count += 1
            next if offset > count
            load_row(row, count)
          end
        end

        private

        def load_row(row, count)
          profile_id = row[:profileid]
          puts "Retrieving publications for: #{profile_id} (row: #{count})"

          wos_file = retrieve_publications(row, profile_id)
          return if File.empty?(wos_file)

          sparql_file = transform_publications(wos_file, profile_id)
          return if File.empty?(sparql_file)

          puts "Loading sparql for #{profile_id}: #{row[:uri]}"
          system("exe/load call Sparql -i #{sparql_file}")
        end

        def transform_publications(wos_file, profile_id)
          sparql_file = File.join(options[:dir], "#{profile_id}.sparql")
          transform = "exe/transform call WebOfScience -i #{wos_file} > #{sparql_file}"
          system(transform)
          sparql_file
        end

        def retrieve_publications(row, profile_id)
          wos_file = File.join(options[:dir], "#{profile_id}.ndj")
          first = Shellwords.escape(row[:first_name])
          last = Shellwords.escape(row[:last_name])
          extract = "exe/extract call WebOfScience --firstname #{first} --lastname #{last} > #{wos_file}"
          system(extract)
          wos_file
        end
      end
    end
  end
end
