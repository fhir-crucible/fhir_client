# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "fhir_client"
  s.summary = "A Gem for handling FHIR client requests in ruby"
  s.description = "A Gem for handling FHIR client requests in ruby"
  s.email = "aquina@mitre.org"
  s.homepage = "https://github.com/hl7-fhir/fhir-svn"
  s.authors = ["Andre Quina", "Jason Walonoski", "Janoo Fernandes"]
  s.version = '1.6.1'

  s.files = s.files = `git ls-files`.split("\n")

  s.add_dependency 'fhir_models', '>= 1.6.1'
  s.add_dependency 'tilt', '>= 1.1'
  s.add_dependency 'rest-client', '~> 1.8'
  s.add_dependency 'oauth2', '~> 1.1'
  s.add_dependency 'activesupport', '>= 3'
  s.add_dependency 'addressable', '>= 2.3'
  s.add_dependency 'rack', '~> 1.6'
  s.add_development_dependency 'pry'
end


