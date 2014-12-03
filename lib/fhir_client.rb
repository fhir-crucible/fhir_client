# Top level include file that brings in all the necessary code
require 'bundler/setup'
require 'rubygems'
require 'yaml'
require 'nokogiri'
require 'fhir_model'
require 'rest_client'

require_relative File.join('.','client_interface.rb')
require_relative File.join('.','resource_address.rb')
require_relative File.join('.','resource_format.rb')
require_relative File.join('.','feed_format.rb')
require_relative File.join('.','model','resource_entry.rb')
require_relative File.join('.','model','bundle.rb')
require_relative File.join('.','model','client_reply.rb')
require_relative File.join('.','model','tag.rb')
