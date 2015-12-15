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

      def read(klass, id, format=@default_format, summary=nil, options = {})
        options = { resource: klass, id: id, format: format }.merge(options)
        options[:summary] = summary if summary
        reply = get resource_url(options), fhir_headers(options)
        reply.resource = parse_reply(klass, format, reply)
        reply.resource_class = klass
        reply
      end

      #
      # Read a resource bundle (an XML ATOM feed)
      #
      def read_feed(klass, format=@default_format_bundle)
        options = { resource: klass, format: format }
        reply = get resource_url(options), fhir_headers(options)
        reply.resource = parse_reply(klass, format, reply)
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
      def vread(klass, id, version_id, format=@default_format)
        options = { resource: klass, id: id, format: format, history: {id: version_id} }
        reply = get resource_url(options), fhir_headers(options)
        reply.resource = parse_reply(klass, format, reply)
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
      def update(resource, id, format=@default_format)
        options = { resource: resource.class, id: id, format: format }
        reply = put resource_url(options), resource, fhir_headers(options)
        reply.resource = parse_reply(resource.class, format, reply)
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
      def destroy(klass, id=nil, options={})
        options = { resource: klass, id: id, format: nil }.merge options
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
      def create(resource, format=@default_format)
        options = { resource: resource.class, format: format }
        reply = post resource_url(options), resource, fhir_headers(options)
        if [200,201].include? reply.code
          type = reply.response[:headers][:content_type]
          if !type.nil?
            if type.include?('xml') && !reply.body.empty?
              reply.resource = resource.class.from_xml(reply.body)
            elsif type.include?('json') && !reply.body.empty?
              reply.resource = resource.class.from_fhir_json(reply.body)
            else
              reply.resource = resource # just send back the submitted resource
            end
          else
            reply.resource = resource # don't know the content type, so return the resource provided
          end
        else
          reply.resource = resource # just send back the submitted resource
        end
        reply.resource_class = resource.class
        reply
      end

    end
  end
end
