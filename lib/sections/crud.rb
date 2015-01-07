module FHIR
  module Sections
    module Crud
      
      #
      # Read the current state of a resource.
      # 
      # @param resource
      # @param id
      # @return
      #

      def read(klass, id, format=FHIR::Formats::ResourceFormat::RESOURCE_XML)
        options = { resource: klass, id: id, format: format }
        reply = get resource_url(options), fhir_headers(options)
        reply.resource = parse_reply(klass, format, reply.body)
        reply.resource_class = klass
        reply
      end

      #
      # Read a resource bundle (an XML ATOM feed)
      #
      def read_feed(klass, format=FHIR::Formats::FeedFormat::FEED_XML)
        options = { resource: klass, format: format }
        reply = get resource_url(options), fhir_headers(options)
        reply.resource = parse_reply(klass, format, reply.body)
        reply.resource_class = klass
        reply
      end

      #
      # Read the state of a specific version of the resource
      # 
      # @param resource
      # @param id
      # @param versionid
      # @return
      #
      def vread(klass, id, version_id, format=FHIR::Formats::ResourceFormat::RESOURCE_XML)
        options = { resource: klass, id: id, format: format, history: {id: version_id} }
        reply = get resource_url(options), fhir_headers(options)
        reply.resource = parse_reply(klass, format, reply.body)
        reply.resource_class = klass
        reply
      end

      def raw_read(options)
        reply = get resource_url(options), fhir_headers(options)
        reply.body
      end

      def raw_read_url(url)
        reply = get url, fhir_headers({})
        reply.body
      end

      
      #
      # Update an existing resource by its id or create it if it is a new resource, not present on the server
      # 
      # @param resourceClass
      # @param resource
      # @param id
      # @return
      #
      # public <T extends Resource> AtomEntry<T> update(Class<T> resourceClass, T resource, String id);
      def update(resource, id, format=FHIR::Formats::ResourceFormat::RESOURCE_XML)
        options = { resource: resource.class, id: id, format: format }
        reply = put resource_url(options), resource, fhir_headers(options)
        # reply.resource = resource.class.from_xml(reply.body)
        reply.resource = resource
        reply.resource_class = resource.class
        reply
      end
      #
      # Update an existing resource by its id or create it if it is a new resource, not present on the server
      # 
      # @param resourceClass
      # @param resource
      # @param id
      # @return
      #
      # public <T extends Resource> AtomEntry<T> update(Class<T> resourceClass, T resource, String id, List<AtomCategory> tags);
      
      #
      # Delete the resource with the given ID.
      # 
      # @param resourceClass
      # @param id
      # @return
      #
      def destroy(klass, id)
        options = { resource: klass, id: id, format: nil }
        reply = delete resource_url(options), fhir_headers(options)
        reply.resource_class = klass
        reply
      end
      # public <T extends Resource> boolean delete(Class<T> resourceClass, String id); 

      #
      # Create a new resource with a server assigned id. Return the newly created
      # resource with the id the server assigned.
      # 
      # @param resourceClass
      # @param resource
      # @return
      #
      def create(resource)
        options = { resource: resource.class, format: nil }
        reply = post resource_url(options), resource, fhir_headers(options)
        #reply.resource = resource.class.from_xml(reply.body)
        # TODO: need to fail on server error
        reply.resource = resource
        reply.resource_class = resource.class   
        reply
      end

    end
  end
end
