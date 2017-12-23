# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'rialto/etl'
require 'webmock/rspec'

def coverage_needed?
  ENV['COVERAGE'] || ENV['TRAVIS']
end

if coverage_needed?
  require 'simplecov'
  require 'coveralls'

  SimpleCov.root(File.expand_path('../..', __FILE__))
  SimpleCov.formatter = Coveralls::SimpleCov::Formatter
  SimpleCov.start do
    add_filter '/spec'
  end
  SimpleCov.command_name 'spec'
  Coveralls.wear!
end

WebMock.disable_net_connect!
