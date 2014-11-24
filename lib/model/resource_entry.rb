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
      regex = %r{(?<=#{@resource_class.name.demodulize}\/)(\w+)}
      if !@resource_class.nil? and !@self_link.nil?
        @self_link =~ regex
        return $1
      elsif !@resource_class.nil? and !@id.nil?
        @id =~ regex
        return $1
      end
      nil
    end

    def resource_version
      regex = %r{(?<=_history\/)(\w+)}
      if !@self_link.nil?
        @self_link =~ regex
        return $1
      elsif !@id.nil?
        @id =~ regex
        return $1
      end
      nil
    end

  end
end