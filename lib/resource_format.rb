module FHIR
  module Formats
    class ResourceFormat
      RESOURCE_XML = 'application/fhir+xml'.freeze
      RESOURCE_JSON = 'application/fhir+json'.freeze

      RESOURCE_XML_DSTU2 = 'application/xml+fhir'.freeze
      RESOURCE_JSON_DSTU2 = 'application/json+fhir'.freeze
    end
  end
end
