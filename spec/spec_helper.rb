# frozen_string_literal: true

def coverage_needed?
  ENV['COVERAGE'] || ENV['TRAVIS']
end

if coverage_needed?
  require 'simplecov'

  SimpleCov.root(File.expand_path('..', __dir__))
  SimpleCov.start do
    add_filter '/spec'
  end
  SimpleCov.command_name 'spec'
end

require 'rialto/etl'
require 'rialto/etl/cli'
require 'webmock/rspec'

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.order = :random
  Kernel.srand config.seed
end
