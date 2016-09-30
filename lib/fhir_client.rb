require 'fhir_client/version'

# require 'yaml'  # not sure what (if anything) this is needed for

require 'fhir_models'
require 'active_support/all'

Dir.chdir 'lib' do
  Dir['fhir_client/sections/*.rb'].each do |file|
    require file
  end
  Dir['fhir_client/ext/*.rb'].each do |file|
    require file
  end
end

require_relative 'fhir_client/client'
require_relative 'fhir_client/resource_address'
require_relative 'fhir_client/resource_format'
require_relative 'fhir_client/patch_format'
require_relative 'fhir_client/model/client_reply'
require_relative 'fhir_client/model/tag'
require_relative 'fhir_client/client_exception'
