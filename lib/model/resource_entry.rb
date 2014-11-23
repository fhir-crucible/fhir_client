module FHIR
  class ResourceEntry
    attr_accessor :id, :self_link, :resource, :title, :last_updated, :published,
                  :author_name, :author_uri, :links, :tags, :resource_class

    def initialize(data)
      data.keys.each do |key|
        method("#{key}=").call(data[key])
      end
    end

    def version
      if !@id.nil?
        # TODO: ???
      end
      nil
    end

    def resource_id
      if !@resource_class.nil? and !@self_link.nil?
        @self_link =~ %r{(?<=#{@resource_class.name.demodulize}\/)(\w+)}
        return $1
      end
      nil
    end

    def resource_version
      if !@self_link.nil?
        @self_link =~ %r{(?<=_history\/)(\w+)}
        return $1
      end
      nil
    end

  end
end