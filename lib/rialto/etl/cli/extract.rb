# frozen_string_literal: true

require 'rialto/etl/extractors'

module Rialto
  module Etl
    module CLI
      # Extract subcommand
      class Extract < Thor
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
          callable_extractors = Rialto::Etl::Extractors.constants.map(&:to_s) - ['StanfordClient']
          say "Extractors supported: #{callable_extractors.join(', ')}"
        end

        private

        def extractor(name)
          Rialto::Etl::Extractors.const_get(name).new
        end
      end
    end
  end
end
