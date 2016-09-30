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
      def validate(resource, options = {}, format = @default_format)
        options.merge!(resource: resource.class, validate: true, format: format)
        params = FHIR::Parameters.new
        add_resource_parameter(params, 'resource', resource)
        add_parameter(params, 'profile', 'Uri', options[:profile_uri]) unless options[:profile_uri].nil?
        post resource_url(options), params, fhir_headers(options)
      end

      def validate_existing(resource, id, options = {}, format = @default_format)
        options.merge!(resource: resource.class, id: id, validate: true, format: format)
        params = FHIR::Parameters.new
        add_resource_parameter(params, 'resource', resource)
        add_parameter(params, 'profile', 'Uri', options[:profile_uri]) unless options[:profile_uri].nil?
        post resource_url(options), params, fhir_headers(options)
      end

      private

      def add_parameter(params, name, type, value)
        params.parameter ||= []
        parameter = FHIR::Parameters::Parameter.new.from_hash(name: name)
        parameter.method("value#{type}=").call(value)
        params.parameter << parameter
      end

      def add_resource_parameter(params, name, resource)
        params.parameter ||= []
        parameter = FHIR::Parameters::Parameter.new.from_hash(name: name)
        parameter.resource = resource
        params.parameter << parameter
      end
    end
  end
end
