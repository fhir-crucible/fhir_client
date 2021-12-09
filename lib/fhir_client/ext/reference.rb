module FHIR
  module ReferenceExtras
    def parts
      return if contained?
      if has_version?
        *base_uri, type, id, _, version = reference.to_s.split '/'
      else
        *base_uri, type, id = reference.to_s.split '/'
      end
      {
        base_uri: (base_uri.empty?) ? nil : base_uri.join('/'),
        type: type,
        id: id,
        version: version
      }
    end

    def contained?
      reference.to_s.start_with?('#')
    end

    def absolute?
      /^https?:\/\//.match reference.to_s
    end

    def relative?
      !(reference.blank? || contained? || absolute?)
    end

    def has_version?
      /_history/.match reference.to_s
    end

    def reference_id
      if contained?
        reference.to_s[1..-1]
      else
        parts[:id]
      end
    end

    def resource_type
      return if contained?
      parts[:type]
    end

    def version_id
      return if contained?
      parts[:version]
    end

    def base_uri
      return if !absolute? || contained?
      parts[:base_uri]
    end

    def read(client = self.client)
      return if !(relative? || absolute?)
      if relative? || reference == client.full_resource_url(resource: resource_class, id: reference_id)
        read_client = client
      else
        read_client = FHIR::Client.new base_uri, default_format: client.default_format, proxy: client.proxy
      end
      resource_class.read(reference_id, read_client)
    end

    def vread(client = self.client)
      return if !(relative? || absolute?) || version_id.blank?
      if relative? || reference == client.full_resource_url(resource: resource_class, id: reference_id)
        read_client = client
      else
        read_client = FHIR::Client.new base_uri, default_format: client.default_format, proxy: client.proxy
      end
      resource_class.vread(reference_id, version_id, read_client)
    end

  end
end

module FHIR
  class Reference
    include FHIR::ReferenceExtras

    def resource_class
      "FHIR::#{resource_type}".constantize unless contained?
    end
  end
end

module FHIR
  module DSTU2
    class Reference
      include FHIR::ReferenceExtras

      def resource_class
        "FHIR::DSTU2::#{resource_type}".constantize unless contained?
      end
    end
  end
end

module FHIR
  module STU3
    class Reference
      include FHIR::ReferenceExtras

      def resource_class
        "FHIR::STU3::#{resource_type}".constantize unless contained?
      end
    end
  end
end
