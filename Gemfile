# frozen_string_literal: true

source 'https://rubygems.org'

# Bundler uses the insecure git protocol by default which causes a warning.
# Switch to HTTPS instead:
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# The released version of oauth2 is very old and won't support Faraday 0.15,
# which we need in order to use net-http-persistent 3.0
gem 'oauth2', github: 'oauth-xx/oauth2'

gem 'activesupport', '~> 5.2'
gem 'config'
gem 'faraday', '~> 0.15.0'
gem 'faraday_middleware'
gem 'httpclient'
gem 'json-ld'
gem 'parallel'
gem 'rdf', '>= 3.0.6' # this version has a mutex around URI minting.
gem 'rdf-vocab'
gem 'ruby-progressbar'
gem 'sparql'
gem 'sparql-client', '~> 3.0'
gem 'thor', '~> 0.20'
gem 'traject_plus', '>= 0.0.2'
gem 'uuid'

group :development, :test do
  gem 'rake', '~> 12.0'
  gem 'rspec', '~> 3.0'
  gem 'rubocop', '~> 0.58.0'
  gem 'rubocop-rspec', '~> 1.21.0'
  gem 'simplecov', require: false
  gem 'webmock'
end

group :development do
  gem 'capistrano-bundler', '~> 1.4'
  gem 'dlss-capistrano', '~> 3.4'
end

# These dependencies are excluded on Travis-CI
group :debug do
  gem 'pry'
  gem 'pry-byebug'
end
