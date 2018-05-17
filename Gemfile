# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in rialto-etl.gemspec
gemspec

group :development, :test do
  gem 'pry' unless ENV['CI']
  gem 'pry-byebug' unless ENV['CI']
  gem 'simplecov', require: false
end
