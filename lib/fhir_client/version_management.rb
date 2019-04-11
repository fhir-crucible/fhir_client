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

    def versioned_format_class(format = nil)
      if @fhir_version == :dstu2
        case format
        when nil
          @default_format.include?('xml') ?
              FHIR::Formats::ResourceFormat::RESOURCE_XML_DSTU2 :
              FHIR::Formats::ResourceFormat::RESOURCE_JSON_DSTU2
        when :xml
          FHIR::Formats::ResourceFormat::RESOURCE_XML_DSTU2
        else
          FHIR::Formats::ResourceFormat::RESOURCE_JSON_DSTU2
        end
      else
        case format
        when nil
          @default_format.include?('xml') ?
              FHIR::Formats::ResourceFormat::RESOURCE_XML :
              FHIR::Formats::ResourceFormat::RESOURCE_JSON
        when :xml
          FHIR::Formats::ResourceFormat::RESOURCE_XML
        else
          FHIR::Formats::ResourceFormat::RESOURCE_JSON
        end
      end
    end

  end
end