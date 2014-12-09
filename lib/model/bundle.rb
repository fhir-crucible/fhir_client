module FHIR
  class Bundle

    attr_accessor :resource_class
    attr_accessor :raw_xml
    attr_accessor :xml
    attr_reader :size, :first_link, :last_link, :next_link, :previous_link

    def initialize(resource_class, raw_xml)
      @resource_class = resource_class
      @raw_xml = raw_xml
      @xml = Nokogiri::XML(raw_xml)
      @xml.root.add_namespace_definition('atom','http://www.w3.org/2005/Atom')
      @xml.root.add_namespace_definition('a9','http://a9.com/-/spec/opensearch/1.1/')
      @xml.root.add_namespace_definition('fhir', 'http://hl7.org/fhir')
      @xml.root.add_namespace_definition('xhtml', 'http://www.w3.org/1999/xhtml')
      @size = Integer(@xml.at_xpath('atom:feed/a9:totalResults').inner_text)
      # set the links
      [:first, :last, :previous, :next].each do |key| 
        instance_variable_set("@#{key}_link".to_sym, @xml.at_xpath("atom:feed/atom:link[@rel='#{key}']/@href").try(:value))
      end
      parse_bundle
    end

    def get(index) 
      return nil unless index >= 0 && index < @size
      @entries[index]
    end

    def entries
      @entries.select {|e| !e.deleted}
    end

    def deleted_entries
      @entries.select {|e| e.deleted}
    end

    def all_entries
      @entries
    end

    def get_by_id(id)
      return nil unless @index_by_id.keys.include?(id)
      @entries[@index_by_id[id]]
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
      @entries = []
      @index_by_id = {}

      @xml.xpath("atom:feed/*[name() = 'deleted-entry'] | atom:feed/*[name() = 'entry']").each_with_index do |entry, index|
        attributes = {}
        attributes[:self_link] = inner_text(entry,"atom:link[@rel='self']/@href")
        attributes[:deleted] = entry.name == 'deleted-entry'
        if attributes[:deleted]
          attributes[:id] = entry.at_xpath('@ref').value
          if !@resource_class.nil?
            attributes[:resource_class] = @resource_class
            id = attributes[:id].split("/").fetch(attributes[:id].split("/").index(@resource_class.name.demodulize)+1)
          end
          attributes[:last_updated] = entry.at_xpath('@when').value
        else
          attributes[:id] = inner_text(entry,'atom:id')
          if !@resource_class.nil?
            content = entry.at_xpath('atom:content/*')
            # TODO bundles can include resource types not requested (for instance, _includes)
            # this deserialization should be more flexible...
            attributes[:resource] = @resource_class.from_xml( content.to_s ) if content
            attributes[:resource_class] = @resource_class
            id = attributes[:id].split("/").fetch(attributes[:id].split("/").index(@resource_class.name.demodulize)+1)
          end
          attributes[:title] = inner_text(entry,'atom:title')
          attributes[:last_updated] = inner_text(entry,'atom:updated')
          attributes[:published] = inner_text(entry,'atom:published')
          attributes[:author_name] = inner_text(entry,'atom:author/atom:name')
        end

        @entries << ResourceEntry.new(attributes)
        @index_by_id[id] = index

      end

    end


  end
end
