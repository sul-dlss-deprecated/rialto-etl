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
      def self.start(*args)
        Base.start(*args)
      end
    end
  end
end
