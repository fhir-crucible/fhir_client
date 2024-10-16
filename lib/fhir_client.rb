require 'fhir_models'
require 'fhir_dstu2_models'
require 'fhir_stu3_models'
require 'active_support/all'

# Default to INFO level logging for all FHIR namespaced logging. Since there is
# no single gem that 'owns' the FHIR namespace, we use the client as the spot
# to set the default. Otherwise the default is set to DEBUG, which is too high.
FHIR.logger.level = Logger::INFO

root = File.expand_path '.', File.dirname(File.absolute_path(__FILE__))
Dir.glob(File.join(root, 'fhir_client', 'sections', '**', '*.rb')).each do |file|
  require file
end
Dir.glob(File.join(root, 'fhir_client', 'ext', '**', '*.rb')).each do |file|
  require file
end

require_relative 'fhir_client/version_management'
require_relative 'fhir_client/client'
require_relative 'fhir_client/resource_address'
require_relative 'fhir_client/resource_format'
require_relative 'fhir_client/return_preferences'
require_relative 'fhir_client/patch_format'
require_relative 'fhir_client/client_exception'
require_relative 'fhir_client/version'

Dir.glob(File.join(root, 'fhir_client', 'model', '**', '*.rb')).each do |file|
  require file
end
