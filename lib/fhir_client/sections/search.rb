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

        reply = if options.dig(:search, :flag).nil? && options.dig(:search, :body).nil?
                  get resource_url(options), fhir_headers
                else
                  options[:search][:flag] = true
                  post resource_url(options), options.dig(:search, :body), fhir_headers({content_type: 'application/x-www-form-urlencoded'})
                end

        reply.resource = parse_reply(klass, format, reply)
        reply.resource_class = klass
        reply
      end

      # It does not appear that this is part of the specification (any more?)
      # Investigate removing in next major version.
      def search_existing(klass, id, options = {}, format = @default_format)
        options[:id] = id
        search(klass, options, format)
      end

      def search_all(options = {}, format = @default_format)
        options[:format] = format
        search(nil, options, format)
      end
    end
  end
end
