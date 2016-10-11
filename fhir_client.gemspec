# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fhir_client/version'

Gem::Specification.new do |spec|
  spec.name          = 'fhir_client'
  spec.version       = FHIR::Client::VERSION
  spec.authors       = ['Andre Quina', 'Jason Walonoski', 'Janoo Fernandes']
  spec.email         = ['aquina@mitre.org']

  spec.summary       = %q{A Gem for handling FHIR client requests in ruby}
  spec.description   = %q{A Gem for handling FHIR client requests in ruby}
  spec.homepage      = 'https://github.com/fhir-crucible/fhir_client'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'activesupport', '>= 3'
  spec.add_dependency 'addressable', '>= 2.3'
  spec.add_dependency 'fhir_models', '>= 1.6.6'
  spec.add_dependency 'nokogiri'
  spec.add_dependency 'oauth2', '~> 1.1'
  spec.add_dependency 'rack', '>= 1.5'
  spec.add_dependency 'rest-client', '~> 1.8'
  spec.add_dependency 'tilt', '>= 1.1'

  spec.add_development_dependency 'bundler', '~> 1.13'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'webmock'
  spec.add_development_dependency 'test-unit'
  spec.add_development_dependency 'simplecov'
end
