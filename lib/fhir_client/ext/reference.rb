module FHIR
  module ReferenceExtras
    def contained?
      reference.to_s.start_with?('#')
    end

    def reference_id
      if contained?
        reference.to_s[1..-1]
      else
        reference.to_s.split('/').last
      end
    end

    def type
      reference.to_s.split('/').first unless contained?
    end

    def read
      return if contained? || type.blank? || (id.blank? && reference.blank?)
      rid = id || reference_id
      resource_class.read(rid, client)
    end
  end
end

module FHIR
  class Reference
    include FHIR::ReferenceExtras

    def resource_class
      "FHIR::#{type}".constantize unless contained?
    end
  end
end

module FHIR
  module DSTU2
    class Reference
      include FHIR::ReferenceExtras
      
      def resource_class
        "FHIR::DSTU2::#{type}".constantize unless contained?
      end
    end
  end
end
