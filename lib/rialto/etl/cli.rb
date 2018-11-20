# frozen_string_literal: true

require 'thor'
require 'rialto/etl'

module Rialto
  module Etl
    # A module to hold command-line interface classes
    module CLI; end
  end
end
require 'active_support/core_ext/module/delegation'
require 'rialto/etl/cli/extract'
require 'rialto/etl/cli/transform'
require 'rialto/etl/cli/load'
require 'rialto/etl/cli/error_reporter'
require 'rialto/etl/cli/grants'
require 'rialto/etl/cli/publications'
