module FHIR
  class Reference
    def read
      # TODO: how to follow contained references?
      type, id = reference.to_s.split("/")
      return unless [type, id].all?(&:present?)
      klass = "FHIR::#{type}".constantize
      klass.read(client, id)
    end
  end
end
