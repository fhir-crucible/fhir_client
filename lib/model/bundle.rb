module FHIR
  class Bundle

    attr_accessor :resource_class
    attr_accessor :raw_xml
    attr_accessor :xml
    attr_reader :size

    def initialize(resource_class, raw_xml)
      @resource_class = resource_class
      @raw_xml = raw_xml
      @xml = Nokogiri::XML(raw_xml)
      @xml.root.add_namespace_definition('atom','http://www.w3.org/2005/Atom')
      @xml.root.add_namespace_definition('a9','http://a9.com/-/spec/opensearch/1.1/')
      @xml.root.add_namespace_definition('fhir', 'http://hl7.org/fhir')
      @xml.root.add_namespace_definition('xhtml', 'http://www.w3.org/1999/xhtml')
      @size = Integer(@xml.at_xpath('atom:feed/a9:totalResults').inner_text)
      # @xml.remove_namespaces! # ignore namespaces!
      # @size = Integer(@xml.at_xpath('feed/totalResults').inner_text)
      parse_bundle
    end

    def get(index) 
      return nil unless index >= 0 && index < @size
      @entries.values[index]
    end

    def get_by_id(id)
      return nil unless @entries.keys.include?(id)
      @entries[id]
    end

    def inner_text(element, xpath)
      e = element.at_xpath(xpath)
      if e.nil?
        return nil
      else
        return e.inner_text
      end
    end

    private

    def parse_bundle
      @entries = {}
      (0..@xml.css('entry').length-1).each do |index|
        # add 1 to allow get method to be 0 indexed
        entry = @xml.at_xpath("atom:feed/atom:entry[#{index+1}]")
        if entry.nil?
          @entries[index] = nil
          next
        end

        attributes = {}
        attributes[:id] = inner_text(entry,'atom:id')
        attributes[:self_link] = inner_text(entry,"atom:link[@rel='self']/@href")
        if !@resource_class.nil?
          attributes[:resource] = @resource_class.from_xml( entry.at_xpath('atom:content/*').to_s )
          attributes[:resource_class] = @resource_class
          id = attributes[:id].split("/").fetch(attributes[:id].split("/").index(@resource_class.name.demodulize)+1)
        end
        attributes[:title] = inner_text(entry,'atom:title')
        attributes[:last_updated] = inner_text(entry,'atom:updated')
        attributes[:published] = inner_text(entry,'atom:published')
        attributes[:author_name] = inner_text(entry,'atom:author/atom:name')

        @entries[id] = ResourceEntry.new(attributes)
      end
    end

  end
end
