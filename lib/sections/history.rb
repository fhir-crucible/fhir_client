module FHIR
  module Sections
    module History
      #
      # Create a new resource with a server assigned id. Return the newly created
      # resource with the id the server assigned. Associates tags with newly created resource.
      #
      # @param resourceClass
      # @param resource
      # @return
      #
      # public <T extends Resource> AtomEntry<OperationOutcome> create(Class<T> resourceClass, T resource, List<AtomCategory> tags);

      #
      # Retrieve the update history for a resource with given id since last update time.
      # Last update may be null TODO - ensure this is the case.
      #
      # @param lastUpdate
      # @param resourceClass
      # @param id
      # @return
      #
      # public <T extends Resource> AtomFeed history(Calendar lastUpdate, Class<T> resourceClass, String id);
      # public <T extends Resource> AtomFeed history(DateAndTime lastUpdate, Class<T> resourceClass, String id);

      def history(options)
        reply = get resource_url(options), fhir_headers(options).except(:history)
        reply.resource = parse_reply(options[:resource], @default_format, reply)
        reply.resource_class = options[:resource]
        reply
      end

      #
      # Retrieve the entire update history for a resource with the given id.
      # Last update may be null TODO - ensure this is the case.
      #
      # @param resourceClass
      # @param id
      # @param lastUpdate
      # @return
      #
      def resource_instance_history_as_of(klass, id, lastUpdate)
        history(resource: klass, id: id, history:{since: lastUpdate})
      end

      def resource_instance_history(klass, id)
        history(resource: klass, id: id, history:{})
      end

      def resource_history(klass)
        history(resource: klass, history:{})
      end

      def resource_history_as_of(klass, lastUpdate)
        history(resource: klass, history:{since: lastUpdate})
      end

      #
      # Retrieve the update history for all resource types since the start of server records.
      #
      def all_history
        history(history:{})
      end

      #
      # Retrieve the update history for all resource types since a specific last update date/time.
      #
      # Note:
      # @param lastUpdate
      # @return
      #
      def all_history_as_of(lastUpdate)
        history(history:{since: lastUpdate})
      end

    end
  end
end
