module FHIR
  module VersionManagement

    def versioned_resource_class(klass = nil)
      mod = case @fhir_version
            when :stu3
              FHIR::STU3
            when :dstu2
              FHIR::DSTU2
            when :r4b
              FHIR::R4B
            when :r5
              FHIR::R5
            else
              FHIR
            end
      return mod if klass.nil?
      mod.const_get(klass)
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