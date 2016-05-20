module FHIR
  class Model

    class << self
      cattr_accessor :configuration
      cattr_accessor :last_response
    end

    def self.configure
      self.configuration ||= Configuration.new
      yield configuration
    end

    # class methods 

    def self.find(id)
      self.last_response = self.configuration.client.read(self, id)
      self.last_response.resource
    end

    def self.all()
      self.last_response = self.configuration.client.read_feed(self)
      self.last_response.resource
    end

    def self.create(resource_hash)
      resource = self.new.from_hash(resource_hash)
      self.last_response = self.configuration.client.create(resource)
      self.last_response.resource
    end

    def self.destroy(id)
      self.last_response = self.configuration.client.destroy(self, id)
      nil
    end

    def self.where(parameters)
      options = { search: { parameters: parameters }}
      self.last_response = self.configuration.client.search(self, options)
      self.last_response.resource
    end

    # instance methods

    def save()
      if self.id.nil?
        self.class.last_response = self.class.configuration.client.create(self)
      else
        self.class.last_response = self.class.configuration.client.update(self, self.id)
      end
      self.class.last_response.resource
    end

    def destroy()
      self.class.destroy(self.id) unless self.id.nil?
    end

    class Configuration
      attr_accessor :client
      attr_accessor :format

      def initialize
        @format = FHIR::Formats::ResourceFormat::RESOURCE_XML
      end
    end

  end
end
