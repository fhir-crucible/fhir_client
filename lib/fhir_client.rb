# Top level include file that brings in all the necessary code
require 'bundler/setup'
require 'rubygems'
require 'yaml'
require 'nokogiri'
require 'fhir_model'
require 'rest_client'

# Simple and verbose loggers
RestClient.log = Logger.new("fhir_client.log", 10, 1024000)
$LOG = Logger.new("fhir_client_verbose.log", 10, 1024000)

root = File.expand_path '..', File.dirname(File.absolute_path(__FILE__))
Dir.glob(File.join(root, 'lib','sections','**','*.rb')).each do |file|
  require file
end

require_relative File.join('.','client_interface.rb')
require_relative File.join('.','resource_address.rb')
require_relative File.join('.','resource_format.rb')
require_relative File.join('.','feed_format.rb')
require_relative File.join('.','model','resource_entry.rb')
require_relative File.join('.','model','bundle.rb')
require_relative File.join('.','model','client_reply.rb')
require_relative File.join('.','model','tag.rb')
require_relative File.join('.','model','parameters.rb')

mongo_config = File.join(root, "config/mongoid.yml")
Mongoid.load!(mongo_config, :test) unless (Mongoid.configured? || !File.exists?(mongo_config))
