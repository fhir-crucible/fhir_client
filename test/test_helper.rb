$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'codeclimate-test-reporter'
CodeClimate::TestReporter.start

require 'simplecov'
require 'pry'
require 'test/unit'
require 'webmock/test_unit'

require 'fhir_client'
