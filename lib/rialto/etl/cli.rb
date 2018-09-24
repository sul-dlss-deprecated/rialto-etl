# frozen_string_literal: true

require 'thor'
require 'rialto/etl'
require 'rialto/etl/cli/extract'
require 'rialto/etl/cli/transform'
require 'rialto/etl/cli/load'
require 'rialto/etl/cli/grants'
require 'rialto/etl/cli/publications'

module Rialto
  module Etl
    # A module to hold command-line interface classes
    module CLI; end
  end
end
