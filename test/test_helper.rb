$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'simplecov'
SimpleCov.start

require 'pry'
require 'test/unit'
require 'webmock/test_unit'
WebMock.disable_net_connect!(allow: %w{codeclimate.com})

require 'fhir_client'
FHIR.logger.level = Logger::ERROR

ACCEPT_REGEX_XML = /^(\s*application\/fhir\+xml\s*)(;\s*charset\s*=\s*utf-8\s*)?$/
ACCEPT_REGEX_JSON = /^(\s*application\/fhir\+json\s*)(;\s*charset\s*=\s*utf-8\s*)?$/

ACCEPT_REGEX_XML_DSTU2 = /^(\s*application\/xml\+fhir\s*)(;\s*charset\s*=\s*utf-8\s*)?$/
ACCEPT_REGEX_JSON_DSTU2 = /^(\s*application\/json\+fhir\s*)(;\s*charset\s*=\s*utf-8\s*)?$/

