# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in rialto-etl.gemspec
gemspec

# Bundler uses the insecure git protocol by default which causes a warning.
# Switch to HTTPS instead:
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# The released version of oauth2 is very old and won't support Faraday 0.15,
# which we need in order to use net-http-persistent 3.0
gem 'oauth2', github: 'oauth-xx/oauth2'

group :development, :test do
  gem 'pry' unless ENV['CI']
  gem 'pry-byebug' unless ENV['CI']
  gem 'simplecov', require: false
end
