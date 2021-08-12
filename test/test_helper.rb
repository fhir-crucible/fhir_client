$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'simplecov'
SimpleCov.start

require 'pry'
require 'test/unit'
require 'webmock/test_unit'

require 'fhir_client'
FHIR.logger = Logger.new('/dev/null')
FHIR::STU3.logger = Logger.new('/dev/null')
FHIR::DSTU2.logger = Logger.new('/dev/null')

ACCEPT_REGEX_XML = /^(\s*application\/fhir\+xml\s*)(;\s*charset\s*=\s*utf-8\s*)?$/
ACCEPT_REGEX_JSON = /^(\s*application\/fhir\+json\s*)(;\s*charset\s*=\s*utf-8\s*)?$/

ACCEPT_REGEX_XML_DSTU2 = /^(\s*application\/xml\+fhir\s*)(;\s*charset\s*=\s*utf-8\s*)?$/
ACCEPT_REGEX_JSON_DSTU2 = /^(\s*application\/json\+fhir\s*)(;\s*charset\s*=\s*utf-8\s*)?$/

