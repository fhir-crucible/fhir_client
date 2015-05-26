module FHIR
  class Parameters

    attr_accessor :parameter

    class ParameterComponent
      attr_accessor :name, :valueType, :value, :resource
    end

    def initialize
      @parameter = []
    end

    def add_parameter(name,type,value)
      p = ParameterComponent.new
      p.name = name
      p.valueType = type
      p.value = value
      @parameter << p
    end

    def add_resource_parameter(name,resource)
      p = ParameterComponent.new
      p.name = name
      p.resource = resource
      @parameter << p
    end

    def to_xml
      xml = '<Parameters xmlns="http://hl7.org/fhir">'
      @parameter.each do |p|
        xml += '<parameter>'
        xml += "<name value=\"#{p.name}\"/>" if !p.name.nil?
        if !p.resource.nil?
          xml += '<resource>'
          xml += p.resource.to_xml({is_root: false})
          xml += '</resource>'          
        elsif !p.value.nil? && !p.valueType.nil?
          xml += "<value#{p.valueType} value=\""
          xml += p.value
          xml += "\"></value#{p.valueType}>"          
        end
        xml += '</parameter>'
      end
      xml += '</Parameters>'
    end

    def to_json
      to_fhir_json
    end

    def to_fhir_json
      hash = {}
      hash['resourceType'] = 'Parameters'
      hash['parameter'] = []
      @parameter.each do |p|
        phash = {}
        phash['name'] = p.name
        if !p.resource.nil?
          phash['resource'] = JSON.parse(p.resource.to_fhir_json)
        elsif !p.value.nil? && !p.valueType.nil?
          phash["value#{p.valueType}"] = p.value
        end
        hash['parameter'] << phash
      end
      JSON.pretty_unparse(hash)
    end

  end
end
