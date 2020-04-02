
module FHIR
  module Sections
    module Search
      #
      # Search a set of resources of a given type.
      #
      # @param klass The type of resource to be searched.
      # @param options A hash of options used to construct the search query.
      # @param headers A hash of headers used in the http request itself.
      # @return FHIR::ClientReply
      #
      def search(klass, options = {}, format = @default_format, headers = {})
        options[:resource] = klass
        options[:format] = format

        reply = if options[:search] && options[:search][:flag]
                  headers[:content_type] = 'application/x-www-form-urlencoded'
                  post resource_url(options), nil, fhir_headers(headers)
                else
                  get resource_url(options), fhir_headers(headers)
                end
        # reply = get resource_url(options), fhir_headers(options)
        reply.resource = parse_reply(klass, format, reply)
        reply.resource_class = klass
        reply
      end

      def search_existing(klass, id, options = {}, format = @default_format, headers = {})
        options.merge!(resource: klass, id: id, format: format)
        # if options[:search][:flag]
        reply = if options[:search] && options[:search][:flag]
                  headers[:content_type] = 'application/x-www-form-urlencoded'
                  post resource_url(options), nil, fhir_headers(headers)
                else
                  get resource_url(options), fhir_headers(headers)
                end
        reply.resource = parse_reply(klass, format, reply)
        reply.resource_class = klass
        reply
      end

      def search_all(options = {}, format = @default_format, headers = {})
        options[:format] = format
        reply = if options[:search] && options[:search][:flag]
                  headers[:content_type] = 'application/x-www-form-urlencoded'
                  post resource_url(options), nil, fhir_headers(headers)
                else
                  get resource_url(options), fhir_headers(headers)
                end
        reply.resource = parse_reply(nil, format, reply)
        reply.resource_class = nil
        reply
      end
    end
  end
end
