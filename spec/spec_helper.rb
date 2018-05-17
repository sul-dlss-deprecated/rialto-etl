# frozen_string_literal: true

def coverage_needed?
  ENV['COVERAGE'] || ENV['TRAVIS']
end

if coverage_needed?
  require 'simplecov'

  SimpleCov.root(File.expand_path('../..', __FILE__))
  SimpleCov.start do
    add_filter '/spec'
  end
  SimpleCov.command_name 'spec'
end

require 'rialto/etl'
require 'rialto/etl/cli'

require 'webmock/rspec'
WebMock.disable_net_connect!
