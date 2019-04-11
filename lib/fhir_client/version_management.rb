module FHIR
  module VersionManagement

    def versioned_resource_class(klass = nil)
      return FHIR if klass.nil?
      if @fhir_version == :stu3
        FHIR::STU3.const_get(klass)
      else
        FHIR::DSTU2.const_get(klass)
      end
    end

  end
end