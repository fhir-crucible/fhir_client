module FHIR
  module Sections
    module Crud

      #
      # Read the current state of a resource.
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
      def update(resource, id, format=@default_format)
        base_update(resource, id, nil, format)
      end

      #
      # Update an existing resource by its id or create it if it is a new resource, not present on the server
      #
      def conditional_update(resource, id, searchParams, format=@default_format)
        options = {
          :search => {
            :flag => false,
            :compartment => nil,
            :parameters => {}
          }
        }
        searchParams.each do |key,value|
          options[:search][:parameters][key] = value
        end
        base_update(resource, id, options, format)
      end

      #
      # Update an existing resource by its id or create it if it is a new resource, not present on the server
      #
      def base_update(resource, id, options, format)
        options = {} if options.nil?
        options[:resource] = resource.class
        options[:format] = format
        options[:id] = id
        reply = put resource_url(options), resource, fhir_headers(options)
        reply.resource = parse_reply(resource.class, format, reply)
        reply.resource_class = resource.class
        reply
      end

      #
      # Partial update using a patchset (PATCH)
      #
      def partial_update(klass, id, patchset, options={}, format=@default_format)
        options = { resource: klass, id: id, format: format }.merge options
        
        if (format == FHIR::Formats::ResourceFormat::RESOURCE_XML)
          options[:format] = FHIR::Formats::PatchFormat::PATCH_XML
          options[:Accept] = format
        elsif (format == FHIR::Formats::ResourceFormat::RESOURCE_JSON)
          options[:format] = FHIR::Formats::PatchFormat::PATCH_JSON
          options[:Accept] = format
        end

        reply = patch resource_url(options), patchset, fhir_headers(options)
        reply.resource = parse_reply(klass, format, reply)
        reply.resource_class = klass
        reply
      end

      #
      # Delete the resource with the given ID.
      #
      def destroy(klass, id=nil, options={})
        options = { resource: klass, id: id, format: nil }.merge options
        reply = delete resource_url(options), fhir_headers(options)
        reply.resource_class = klass
        reply
      end

      #
      # Create a new resource with a server assigned id. Return the newly created
      # resource with the id the server assigned.
      #
      def create(resource, format=@default_format)
        base_create(resource, nil ,format)
      end

      #
      # Conditionally create a new resource with a server assigned id.
      #
      def conditional_create(resource, ifNoneExistParameters, format=@default_format)
        query = ''
        ifNoneExistParameters.each do |key,value|
          query += "#{key.to_s}=#{value.to_s}&"
        end
        query = query[0..-2] # strip off the trailing ampersand
        options = {}
        options['If-None-Exist'] = query
        base_create(resource, options, format)
      end

      #
      # Create a new resource with a server assigned id. Return the newly created
      # resource with the id the server assigned.
      #
      def base_create(resource, options, format)
        options = {} if options.nil?
        options[:resource] = resource.class
        options[:format] = format
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
