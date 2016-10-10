module FHIR
  class Reference
    def contained?
      reference.to_s.start_with?('#')
    end

    def id
      if contained?
        reference.to_s[1..-1]
      else
        reference.to_s.split('/').last
      end
    end

    def type
      reference.to_s.split('/').first unless contained?
    end

    def resource_class
      "FHIR::#{type}".constantize unless contained?
    end

    def read
      return if contained? || type.blank? || id.blank?
      resource_class.read(id, client)
    end
  end
end
