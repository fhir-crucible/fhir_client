module FHIR
  module Sections
    module Search
      #
      # Search a set of resources of a given type.
      #
      # @param klass The type of resource to be searched.
      # @param options A hash of options used to construct the search query.
      # @return FHIR::ClientReply
      #
      def search(klass, options = {}, format = @default_format)
        options[:resource] = klass
        options[:format] = format

        reply = if options[:search] && options[:search][:flag]
                  post resource_url(options), nil, fhir_headers(options)
                else
                  get resource_url(options), fhir_headers(options)
                end
        # reply = get resource_url(options), fhir_headers(options)
        reply.resource = parse_reply(klass, format, reply)
        reply.resource_class = klass
        reply
      end

      def search_existing(klass, id, options = {}, format = @default_format)
        options.merge!(resource: klass, id: id, format: format)
        # if options[:search][:flag]
        reply = if options[:search] && options[:search][:flag]
                  post resource_url(options), nil, fhir_headers(options)
                else
                  get resource_url(options), fhir_headers(options)
                end
        reply.resource = parse_reply(klass, format, reply)
        reply.resource_class = klass
        reply
      end

      def search_all(options = {}, format = @default_format)
        options[:format] = format
        reply = if options[:search] && options[:search][:flag]
                  post resource_url(options), nil, fhir_headers(options)
                else
                  get resource_url(options), fhir_headers(options)
                end
        reply.resource = parse_reply(nil, format, reply)
        reply.resource_class = nil
        reply
      end
    end
  end
end
