# Top level include file that brings in all the necessary code
require 'bundler/setup'
require 'rubygems'
require 'yaml'
require 'nokogiri'
require 'fhir_models'
require 'rest_client'
require 'addressable/uri'
require 'oauth2'

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
require_relative File.join('.','patch_format.rb')
require_relative File.join('.','model','bundle.rb')
require_relative File.join('.','model','client_reply.rb')
require_relative File.join('.','model','tag.rb')

begin
	generator = FHIR::Boot::Generator.new
	# 1. generate the lists of primitive data types, complex types, and resources
	generator.generate_metadata
	# 2. generate the complex data types
	generator.generate_types
	# 3. generate the base Resources
	generator.generate_resources
rescue Exception => e 
	$LOG.error("Could not re-generate fhir models... this can happen in production, but the code does not need to be re-generated")
end
