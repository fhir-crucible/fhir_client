module FHIR
  class Model

    attr_accessor :client

    class << self
      cattr_accessor :configuration
    end

    def self.configure
      self.configuration ||= Configuration.new
      yield configuration
    end

    # class methods 

    def self.find(id, options = {})
      client = self.pull_client_from options
      response = client.read(self, id)
      response.resource.client = client
      response.resource
    end

    def self.all(options = {})
      client = pull_client_from options
      response = client.read_feed(self)
      response.resource.client = client
      response.resource
    end

    def self.create(options)
      client = pull_client_from options
      resource = self.new.from_hash(options)
      response = client.create(resource)
      response.resource.client = client
      response.resource
    end

    def self.destroy(id, options = {})
      client = pull_client_from options
      response = client.destroy(self, id)
      nil
    end

    def self.where(options)
      client = pull_client_from options

      options = { search: { parameters: options }}
      response = client.search(self, options)
      response.resource.client = client
      response.resource
    end

    # instance methods

    def save(options = {})
      client = self.class.pull_client_from options, @client
      if self.id.nil?
        last_response = client.create(self)
      else
        last_response = client.update(self, self.id)
      end
      last_response.resource
    end

    def destroy(options = {})
      client = self.class.pull_client_from options, @client
      self.class.destroy(self.id, client: client) unless self.id.nil?
    end

    private

    def self.pull_client_from(options, instance_client = nil)
      options.delete(:client) || instance_client || self.configuration.client
    end

    class Configuration
      attr_accessor :client
    end

  end
end
