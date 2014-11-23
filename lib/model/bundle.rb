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
    end

    def get(index) 
      if( (index < 0) or (index >= @size))
        return nil
      end

      # add 1 to allow get method to be 0 indexed
      entry = @xml.at_xpath("atom:feed/atom:entry[#{index+1}]")
      if entry.nil?
        return nil
      end

      attributes = {}
      attributes[:id] = inner_text(entry,'atom:id')
      attributes[:self_link] = inner_text(entry,"atom:link[@rel='self']/@href")
      if !@resource_class.nil?
        attributes[:resource] = @resource_class.from_xml( entry.at_xpath('atom:content/*').to_s )
        attributes[:resource_class] = @resource_class
      end
      attributes[:title] = inner_text(entry,'atom:title')
      attributes[:last_updated] = inner_text(entry,'atom:updated')
      attributes[:published] = inner_text(entry,'atom:published')
      attributes[:author_name] = inner_text(entry,'atom:author/atom:name')
      # attributes[:author_uri] = entry.at_xpath('author/uri')
      # attributes[:links] = entry.at_xpath('link')
      # attributes[:tags] = entry.at_xpath('tags')

      ResourceEntry.new(attributes)
    end

    def inner_text(element, xpath)
      e = element.at_xpath(xpath)
      if e.nil?
        return nil
      else
        return e.inner_text
      end
    end

  end
end
