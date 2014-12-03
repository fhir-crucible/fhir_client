module FHIR
  module Sections
    module Validate
      #
      # Validate resource payload.
      # 
      # @param resourceClass
      # @param resource
      # @param id
      # @return
      #
      # public <T extends Resource> AtomEntry<OperationOutcome> validate(Class<T> resourceClass, T resource, String id);
      def validate(resource, options={}, format=FHIR::Formats::ResourceFormat::RESOURCE_XML)
        options.merge!({ resource: resource.class, validate: true, format: format })
        post resource_url(options), resource, fhir_headers(options)
      end

      def validate_existing(resource, id, options={}, format=FHIR::Formats::ResourceFormat::RESOURCE_XML)
        options.merge!({ resource: resource.class, id: id, validate: true, format: format })
        post resource_url(options), resource, fhir_headers(options)
      end

    end
  end
end

