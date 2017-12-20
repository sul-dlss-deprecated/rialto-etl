# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rialto/etl/version'

Gem::Specification.new do |spec|
  spec.name          = "rialto-etl"
  spec.version       = Rialto::Etl::VERSION
  spec.authors       = ["Michael J. Giarlo"]
  spec.email         = ["mjgiarlo@stanford.edu"]

  spec.summary       = "ETL tools for RIALTO, Stanford University Libraries' research intelligence project"
  spec.homepage      = 'https://github.com/sul-dlss-labs/rialto-etl'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'faraday'
  spec.add_dependency 'httpclient'

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency 'rubocop', '~> 0.52.0'
end
