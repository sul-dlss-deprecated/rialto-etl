# frozen_string_literal: true

require 'thor'
require 'rialto/etl'
require 'rialto/etl/cli/extract'
require 'rialto/etl/cli/transform'
require 'rialto/etl/cli/base'

module Rialto
  module Etl
    # A module to hold command-line interface classes
    module CLI
      # Module-level method that delegates to the Base command class.
      #   This is provided as a convenience to downstream clients.
      def self.start(*args)
        Base.start(*args)
      end
    end
  end
end
