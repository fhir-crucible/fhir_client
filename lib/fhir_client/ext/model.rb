module FHIR
  class Model
    cattr_accessor :client, instance_accessor: false

    def client
      @@client
    end

    def client=(client)
      @@client = client

      # Ensure the client-setting cascades to all child models
      instance_values.each do |_key, values|
        Array.wrap(values).each do |value|
          next unless value.is_a?(FHIR::Model)
          next if value.client == client
          value.client = client
        end
      end
    end

    def self.read(id, client = @@client)
      handle_response client.read(self, id)
    end

    def self.read_with_summary(id, summary, client = @@client)
      handle_response client.read(self, id, client.default_format, summary)
    end

    def self.vread(id, version_id, client = @@client)
      handle_response client.vread(self, id, version_id)
    end

    def self.resource_history(client = @@client)
      handle_response client.resource_history(self)
    end

    def self.resource_history_as_of(last_update, client = @@client)
      handle_response client.resource_history_as_of(self, last_update)
    end

    def self.resource_instance_history(id, client = @@client)
      handle_response client.resource_instance_history(self, id)
    end

    def self.resource_instance_history_as_of(id, last_update, client = @@client)
      handle_response client.resource_instance_history_as_of(self, id, last_update)
    end

    def self.search(params = {}, client = @@client)
      handle_response client.search(self, search: { parameters: params })
    end

    def self.create(model, client = @@client)
      model = new(model) unless model.is_a?(self)
      handle_response client.create(model)
    end

    def self.conditional_create(model, params, client = @@client)
      model = new(model) unless model.is_a?(self)
      handle_response client.conditional_create(model, params)
    end

    def self.partial_update(id, patchset, options = {})
      handle_response client.partial_update(self, id, patchset, options = {})
    end

    def self.all(client = @@client)
      handle_response client.read_feed(self)
    end

    def vread(version_id)
      self.class.vread(id, version_id, client)
    end

    def create
      handle_response client.create(self)
    end

    def conditional_create(params)
      handle_response client.conditional_create(self, params)
    end

    def update
      handle_response client.update(self, id)
    end

    def conditional_update(params)
      handle_response client.conditional_update(self, id, params)
    end

    def destroy
      handle_response client.destroy(self.class, id) unless id.nil?
      nil
    end

    def resolve(reference)
      if reference.contained?
        contained.detect { |c| c.id == reference.id }
      else
        reference.read
      end
    end

    private

    def self.handle_response(response)
      raise ClientException.new "Server returned #{response.code}.", response if response.code.between?(400, 599)
      response.resource
    end

    def handle_response(response)
      self.class.handle_response(response)
    end
  end
end
