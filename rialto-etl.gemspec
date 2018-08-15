# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rialto/etl/version'

Gem::Specification.new do |spec|
  spec.name          = 'rialto-etl'
  spec.version       = Rialto::Etl::VERSION
  spec.authors       = ['Michael J. Giarlo']
  spec.email         = ['mjgiarlo@stanford.edu']

  spec.summary       = "ETL tools for RIALTO, Stanford University Libraries' research intelligence project"
  spec.homepage      = 'https://github.com/sul-dlss-labs/rialto-etl'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'config'
  spec.add_dependency 'faraday'
  spec.add_dependency 'httpclient'
  spec.add_dependency 'rdf'
  spec.add_dependency 'ruby-progressbar'
  spec.add_dependency 'sparql-client', '~> 3.0'
  spec.add_dependency 'thor', '~> 0.20'
  spec.add_dependency 'traject_plus', '>= 0.0.2'
  spec.add_dependency 'uuid'

  spec.add_development_dependency 'bundler', '~> 1.11'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0.52.0'
  spec.add_development_dependency 'rubocop-rspec', '~> 1.21.0'
  spec.add_development_dependency 'webmock'
end
