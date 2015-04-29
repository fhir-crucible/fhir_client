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
        params = FHIR::Parameters.new
        params.add_resource_parameter('resource',resource)
        params.add_parameter('profile','Uri',options[:profile_uri]) if !options[:profile_uri].nil?
        post resource_url(options), params, fhir_headers(options)
      end

      def validate_existing(resource, id, options={}, format=FHIR::Formats::ResourceFormat::RESOURCE_XML)
        options.merge!({ resource: resource.class, id: id, validate: true, format: format })
        params = FHIR::Parameters.new
        params.add_resource_parameter('resource',resource)
        params.add_parameter('profile','Uri',options[:profile_uri]) if !options[:profile_uri].nil?
        post resource_url(options), params, fhir_headers(options)
      end

    end
  end
end

