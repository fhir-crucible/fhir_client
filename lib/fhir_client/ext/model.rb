module FHIR
  module ModelExtras

    def self.included base
      base.include InstanceMethods
      base.extend ClassMethods
      base.attr_writer :client
    end

    module InstanceMethods
      def client
        @client || FHIR::Model.client
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
      def handle_response(response)
        raise client.exception_class.new "Server returned #{response.code}.", response if response.code.between?(400, 599)
        response.resource
      end
    end

    module ClassMethods

      def client
        FHIR::Model.client
      end

      def client=(client)
        FHIR::Model.client = client
      end

      def read(id, client = self.client)
        handle_response client.exception_class, client.read(self, id)
      end

      def read_with_summary(id, summary, client = self.client)
        handle_response client.exception_class, client.read(self, id, client.default_format, summary)
      end

      def vread(id, version_id, client = self.client)
        handle_response client.exception_class, client.vread(self, id, version_id)
      end

      def resource_history(client = self.client)
        handle_response client.exception_class, client.resource_history(self)
      end

      def resource_history_as_of(last_update, client = self.client)
        handle_response client.exception_class, client.resource_history_as_of(self, last_update)
      end

      def resource_instance_history(id, client = self.client)
        handle_response client.exception_class, client.resource_instance_history(self, id)
      end

      def resource_instance_history_as_of(id, last_update, client = self.client)
        handle_response client.exception_class, client.resource_instance_history_as_of(self, id, last_update)
      end

      def search(params = {}, client = self.client)
        handle_response client.exception_class, client.search(self, search: { parameters: params })
      end

      def create(model, client = self.client)
        model = new(model) unless model.is_a?(self)
        handle_response client.exception_class, client.create(model)
      end

      def conditional_create(model, params, client = self.client)
        model = new(model) unless model.is_a?(self)
        handle_response client.exception_class, client.conditional_create(model, params)
      end

      def partial_update(id, patchset, options = {})
        handle_response client.exception_class, client.partial_update(self, id, patchset, options)
      end

      def all(client = self.client)
        handle_response client.exception_class, client.read_feed(self)
      end

      private

      def handle_response(exception_class, response)
        raise exception_class.new "Server returned #{response.code}.", response if response.code.between?(400, 599)
        response.resource
      end
    end
  end
end

module FHIR
  class Model
    include FHIR::ModelExtras
    cattr_accessor :client, instance_accessor: false
  end
end

module FHIR
  module DSTU2
    class Model
      include FHIR::ModelExtras
    end
  end
end

module FHIR
  module STU3
    class Model
      include FHIR::ModelExtras
    end
  end
end
