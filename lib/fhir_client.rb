require 'fhir_models'
require 'active_support/all'

root = File.expand_path '.', File.dirname(File.absolute_path(__FILE__))
Dir.glob(File.join(root, 'fhir_client', 'sections', '**', '*.rb')).each do |file|
  require file
end
Dir.glob(File.join(root, 'fhir_client', 'ext', '**', '*.rb')).each do |file|
  require file
end

require_relative 'fhir_client/gem_ext'
require_relative 'fhir_client/client'
require_relative 'fhir_client/resource_address'
require_relative 'fhir_client/resource_format'
require_relative 'fhir_client/patch_format'
require_relative 'fhir_client/client_exception'
require_relative 'fhir_client/version'

Dir.glob(File.join(root, 'fhir_client', 'model', '**', '*.rb')).each do |file|
  require file
end
