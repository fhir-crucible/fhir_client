module FHIR
  module Sections
    module Crud
      #
      # Read the current state of a resource.
      #
      def read(klass, id, format = nil, summary = nil, options = {})
        options = { resource: klass, id: id, format: format || @default_format}.merge(options)
        options[:summary] = summary if summary
        headers = { accept: "#{format}" } if format
        reply = get resource_url(options), fhir_headers(headers)
        reply.resource = parse_reply(klass, format || @default_format, reply)
        reply.resource_class = klass
        reply
      end

      #
      # Conditionally Read the resource if it has been modified since the supplied date
      #
      # See If-Modified-Since RRC 7232 https://tools.ietf.org/html/rfc7232#section-3.3 and
      # See HTTP-date https://tools.ietf.org/html/rfc7231#section-7.1.1.1
      #
      # @param klass the FHIR Resource class
      # @param id the resource id
      # @param since_date the date
      def conditional_read_since(klass, id, since_date, options = {})

        options = { resource: klass, id: id}.merge(options)
        headers = { if_modified_since: since_date }
        reply = get resource_url(options), fhir_headers(headers)
        reply.resource = parse_reply(klass, @default_format, reply)
        reply.resource_class = klass
        reply
      end

      #
      # Conditionally Read the resource based on the provided ETag
      #
      # @param klass the FHIR Resource class
      # @param id the resource id
      # @param version_id the version_id used for the ETag
      def conditional_read_version(klass, id, version_id, options = {})

        options = { resource: klass, id: id}.merge(options)
        headers = { if_none_match: "W/#{version_id}" }
        reply = get resource_url(options), fhir_headers(headers)
        reply.resource = parse_reply(klass, @default_format, reply)
        reply.resource_class = klass
        reply
      end

      #
      # Read a resource bundle (an XML ATOM feed)
      #
      #
      def read_feed(klass, format = nil)
        headers = { accept: "#{format}" } if format
        format ||= @default_format
        options = { resource: klass, format: format}
        reply = get resource_url(options), fhir_headers(headers)
        reply.resource = parse_reply(klass, format, reply)
        reply.resource_class = klass
        reply
      end

      #
      # Read the state of a specific version of the resource
      #
      def vread(klass, id, version_id, format = nil)
        headers = { accept: "#{format}" } if format
        format ||= @default_format
        options = { resource: klass, id: id, format: format, history: { id: version_id } }
        reply = get resource_url(options), fhir_headers(headers)
        reply.resource = parse_reply(klass, format, reply)
        reply.resource_class = klass
        reply
      end

      def raw_read(options)
        get resource_url(options), fhir_headers
      end

      def raw_read_url(url, format = nil)
        headers = { accept: "#{format}" } if format
        get url, fhir_headers(headers)
      end

      #
      # Update an existing resource by its id or create it if it is a new resource, not present on the server
      #
      def update(resource, id, format = nil)
        base_update(resource, id, nil, format)
      end

      #
      # Update an existing resource by its id or create it if it is a new resource, not present on the server
      #
      def conditional_update(resource, id, search_params, format = nil)
        options = {
          search: {
            flag: false,
            compartment: nil,
            parameters: {}
          }
        }
        search_params.each do |key, value|
          options[:search][:parameters][key] = value
        end
        base_update(resource, id, options, format)
      end

      #
      # Version Aware Update using version_id
      # prevents Lost Update Problem https://www.w3.org/1999/04/Editing/
      # @param resource the FHIR resource object
      # @param id the resource id
      def version_aware_update(resource, id, version_id, format = nil, options = {})
        base_update(resource, id, options, format, {if_match: "W/#{version_id}"})
      end

      #
      # Update an existing resource by its id or create it if it is a new resource, not present on the server
      #
      def base_update(resource, id, options, format = nil, headers = nil)
        headers ||= {}
        headers[:accept] = "#{format}" if format
        format ||= @default_format
        headers[:content_type] =  "#{format}"
        headers[:prefer] = @return_preference if @use_return_preference
        options = {} if options.nil?
        options[:resource] = resource.class
        options[:format] = format
        options[:id] = id
        reply = put resource_url(options), resource, fhir_headers(headers)
        reply.resource = parse_reply(resource.class, format, reply) if reply.body.present?
        reply.resource_class = resource.class
        reply
      end

      #
      # Partial update using a patchset (PATCH)
      #
      def partial_update(klass, id, patchset, options = {}, format = nil)
        headers = {}
        headers[:accept] =  "#{format}" if format
        format ||= @default_format
        options = { resource: klass, id: id, format: format}.merge options
        if [FHIR::Formats::ResourceFormat::RESOURCE_XML, FHIR::Formats::ResourceFormat::RESOURCE_XML_DSTU2].include?(format)
          options[:format] = FHIR::Formats::PatchFormat::PATCH_XML
          headers[:content_type] =  "#{FHIR::Formats::PatchFormat::PATCH_XML}"
        elsif [FHIR::Formats::ResourceFormat::RESOURCE_JSON, FHIR::Formats::ResourceFormat::RESOURCE_JSON_DSTU2].include?(format)
          options[:format] = FHIR::Formats::PatchFormat::PATCH_JSON
          headers[:content_type] =  "#{FHIR::Formats::PatchFormat::PATCH_JSON}"
        end
        headers[:prefer] = @return_preference if @use_return_preference
        reply = patch resource_url(options), patchset, fhir_headers(headers)
        reply.resource = parse_reply(klass, format, reply)
        reply.resource_class = klass
        reply
      end

      #
      # Delete the resource with the given ID.
      #
      def destroy(klass, id = nil, options = {})
        options = { resource: klass, id: id, format: @default_format }.merge options
        reply = delete resource_url(options), fhir_headers
        reply.resource_class = klass
        reply
      end

      #
      # Create a new resource with a server assigned id. Return the newly created
      # resource with the id the server assigned.
      #
      def create(resource, options = {}, format = nil)
        base_create(resource, options, format)
      end

      #
      # Conditionally create a new resource with a server assigned id.
      #
      def conditional_create(resource, if_none_exist_parameters, format = nil)
        query = ''
        if_none_exist_parameters.each do |key, value|
          query += "#{key}=#{value}&"
        end
        query = query[0..-2] # strip off the trailing ampersand
        header = {if_none_exist: query}
        base_create(resource, nil, format, header)
      end

      #
      # Create a new resource with a server assigned id. Return the newly created
      # resource with the id the server assigned.
      #
      def base_create(resource, options, format = nil, additional_header = {})
        headers = {}
        headers[:accept] = "#{format}" if format
        format ||= @default_format
        headers = {content_type: "#{format}"}
        headers[:prefer] = @return_preference if @use_return_preference
        headers.merge!(additional_header)
        options = {} if options.nil?
        options[:resource] = resource.class
        options[:format] = format || @default_format
        reply = post resource_url(options), resource, fhir_headers(headers)
        if [200, 201].include? reply.code
          type = reply.response[:headers].detect{|x, _y| x.downcase=='content-type'}.try(:last)
          if !type.nil?
            reply.resource = if type.include?('xml') && !reply.body.empty?
                               klass = self.versioned_resource_class(:Xml)
                               klass.from_xml(reply.body)
                             elsif type.include?('json') && !reply.body.empty?
                               klass = self.versioned_resource_class(:Json)
                               klass.from_json(reply.body)
                             else
                               resource # just send back the submitted resource
                             end
            resource.id = FHIR::ResourceAddress.pull_out_id(resource.class.name.demodulize, reply.self_link)
          else
            resource.id = FHIR::ResourceAddress.pull_out_id(resource.class.name.demodulize, reply.self_link)
            reply.resource = resource # don't know the content type, so return the resource provided
          end
        else
          resource.id = FHIR::ResourceAddress.pull_out_id(resource.class.name.demodulize, reply.self_link)
          reply.resource = resource # just send back the submitted resource
        end
        set_client_on_resource(reply.resource)
        reply.resource_class = resource.class
        reply
      end
    end
  end
end
