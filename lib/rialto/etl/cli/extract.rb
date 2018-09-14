# frozen_string_literal: true

require 'rialto/etl/extractors'

module Rialto
  module Etl
    module CLI
      # Extract subcommand
      class Extract < Thor
        option :firstname,
               required: false,
               banner: 'FIRSTNAME',
               desc: 'First name of the researcher (for WebOfScience)',
               aliases: '-f'

        option :lastname,
               required: false,
               banner: 'LASTNAME',
               desc: 'Last name of the researcher (for WebOfScience)',
               aliases: '-l'

        option :institution,
               required: false,
               banner: 'INSTITUTION',
               desc: 'Institution name (for WebOfScience)',
               aliases: '-i'

        option :sunetid,
               required: false,
               banner: 'SUNETID',
               desc: 'SUNet ID (for SeRA API)',
               aliases: '-s'

        desc 'call NAME', "Call named extractor (`#{@package_name} list` to see available names)"
        # Call a extractor by name
        def call(name)
          extractor(name).each do |out|
            say out
          end
        end

        desc 'list', 'List callable extractors'
        # List callable extractors
        def list
          callable_extractors = Rialto::Etl::Extractors.constants.map(&:to_s).sort
          say "Extractors supported: #{callable_extractors.join(', ')}"
        end

        private

        def extractor(name)
          Rialto::Etl::Extractors.const_get(name).new(options)
        end
      end
    end
  end
end
