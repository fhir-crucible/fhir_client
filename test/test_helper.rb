$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'simplecov'
SimpleCov.start

require 'pry'
require 'test/unit'
require 'webmock/test_unit'
WebMock.disable_net_connect!(allow: %w{codeclimate.com})

require 'fhir_client'
FHIR.logger.level = Logger::ERROR
