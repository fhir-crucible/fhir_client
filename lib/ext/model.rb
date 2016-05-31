module FHIR
  class Model
    attr_reader :client

    def client=(client)
      @client = client

      # Ensure the client-setting cascades to all child models
      instance_values.each do |_key, values|
        Array.wrap(values).each do |value|
          next unless value.is_a?(FHIR::Model)
          next if value.client == client
          value.client = client
        end
      end
    end

    def self.read(client, id)
      client.read(self, id).resource
    end

    def self.search(client, params = {})
      client.search(self, search: { parameters: params }).resource
    end

    def self.create(client, model)
      model = self.new(model) unless model.is_a?(self)
      client.create(model).resource
    end

    def update
      client.update(self, id).resource
    end

    def destroy
      client.destroy(self, id)
    end
  end
end
