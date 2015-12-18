module FHIR
  class Parameters

    attr_accessor :xmlId, :parameter

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

    def self.from_fhir_json(json)
       # if the input is a String, convert it into a Hash
      if json.is_a? String
        begin
          if json.encoding.names.include? 'UTF-8'
            json.gsub!("\xEF\xBB\xBF".force_encoding('UTF-8'), '') # remove UTF-8 BOM
          end
          hash = JSON.parse(json)
        rescue Exception => e
          $LOG.error "Failed to parse JSON hash as resource: #{e.message} %n #{json} %n #{e.backtrace.join("\n")}"
          return nil
        end
      end
      
      resourceType = hash['resourceType']
      return FHIR::Resource.from_contents(json) if !resourceType.nil? && resourceType!='Parameters'

      obj = FHIR::Parameters.new
      hash['parameter'].each do |phash|
        pname = phash['name']
        presource = phash['resource']
        if !presource.nil?
          presource = FHIR::Resource.from_contents(JSON.pretty_unparse(presource))
          obj.add_resource_parameter(pname,presource)
        else
          key = phash.keys.select{|k|k.start_with?'value'}.first
          pvalue = phash[key]
          pvalueType = key[5..-1]
          obj.add_parameter(pname,pvalueType,pvalue)
        end
      end
      obj
    end

    def self.from_xml(xml)
      doc = Nokogiri::XML(xml)
      doc.root.add_namespace_definition('fhir', 'http://hl7.org/fhir')
      doc.root.add_namespace_definition('xhtml', 'http://www.w3.org/1999/xhtml')
      entry = doc.at_xpath("./fhir:#{self.name.demodulize}")
      
      obj = FHIR::Parameters.new
      entry.xpath('./fhir:parameter').each do |p|
        pname = p.at_xpath('./fhir:name/@value').try(:value)
        presource = p.at_xpath('./fhir:resource/*').try(:to_xml)
        if !presource.nil?
          rdoc = Nokogiri::XML(presource)
          add_namespace_definition(rdoc.root)
          presource = FHIR::Resource.from_contents(rdoc.to_xml)
          obj.add_resource_parameter(pname,presource)
        else
          key = p.xpath('./*').select{|x|x.name.start_with?'value'}.try(:first).try(:name)
          unless key.nil?
            pvalue = p.at_xpath("./fhir:#{key}/@value").try(:value)
            pvalueType = key[5..-1]
            obj.add_parameter(pname,pvalueType,pvalue)
          end
        end
      end
      obj
    end

    def self.add_namespace_definition(element)
      element.namespace=element.add_namespace_definition('fhir', 'http://hl7.org/fhir')
      element.add_namespace_definition('xhtml', 'http://www.w3.org/1999/xhtml')
      element.children.select{|e|e.class==Nokogiri::XML::Element}.each do |e|
        add_namespace_definition(e)
      end
    end

  end
end
