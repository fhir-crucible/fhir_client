# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fhir_client/version'

Gem::Specification.new do |spec|
  spec.name          = 'fhir_client'
  spec.version       = FHIR::Client::VERSION
  spec.authors       = ['Andre Quina', 'Jason Walonoski', 'Robert Scanlon', 'Reece Adamson']
  spec.email         = ['jwalonoski@mitre.org']
  spec.licenses      = ['Apache-2.0']

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
  spec.add_dependency 'fhir_models', '>= 4.2.1'
  spec.add_dependency 'fhir_stu3_models', '>= 3.1.1'
  spec.add_dependency 'fhir_dstu2_models', '>= 1.1.1'
  spec.add_dependency 'nokogiri', '>= 1.10.4'
  spec.add_dependency 'oauth2', '>= 1.1'
  spec.add_dependency 'rack', '>= 1.5'
  spec.add_dependency 'faraday', '~> 2.0'
  spec.add_dependency 'tilt', '>= 1.1'

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '>= 12.3.3'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'webmock'
  spec.add_development_dependency 'test-unit'
  spec.add_development_dependency 'simplecov'
end
