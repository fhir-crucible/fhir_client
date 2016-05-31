module FHIR
  class Model
    attr_reader :client

    def client=(client)
      @client = client

      # Ensure the client-setting cascades to all child models
      instance_values.each do |key, values|
        Array.wrap(values).each do |value|
          next unless value.is_a?(FHIR::Model)
          next if value.client == client
          value.client = client
        end
      end
    end

    def self.resource_for(reply)
      reply.resource || raise("Request #{reply.request} failed with #{reply.response}")
    end

    def self.read(client, id)
      model = resource_for(client.read(self, id))
      model.tap { |m| m.client = client }
    end

    def self.search(client, params)
      # TODO: if there are multiple pages, either fetch them all or return an
      # enumerator that can lazily fetch the rest
      bundle = resource_for(client.search(self, search: { parameters: params }))
      models = bundle.entry.map(&:resource)
      models.each { |m| m.client = client }
    end
  end

  class Reference
    def read
      raise "Missing client, unable to follow reference" unless client
      # TODO: how to follow contained references?
      type, id = reference.to_s.split("/")
      return unless [type, id].all?(&:present?)
      klass = "FHIR::#{type}".constantize
      klass.read(client, id)
    end
  end
end
