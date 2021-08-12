module FHIR
  module Sections
    module Transactions
      attr_accessor :transaction_bundle

      def begin_transaction
        @transaction_bundle = versioned_resource_class('Bundle').new
        @transaction_bundle.type = 'transaction'
        @transaction_bundle.entry ||= []
        @transaction_bundle
      end

      def begin_batch
        @transaction_bundle = versioned_resource_class('Bundle').new
        @transaction_bundle.type = 'batch'
        @transaction_bundle.entry ||= []
        @transaction_bundle
      end

      # syntactic sugar for add_batch_request
      # @param method one of ['GET','POST','PUT','DELETE']
      # @param url relative path, such as 'Patient/123'. Do not include the [base]
      # @param resource The resource if a POST or PUT
      def add_transaction_request(method, url, resource = nil, if_none_exist = nil)
        add_batch_request(method, url, resource, if_none_exist)
      end

      def add_batch_request(method, url, resource = nil, if_none_exist = nil)
        request = versioned_resource_class('Bundle::Entry::Request').new
        request.local_method = if versioned_resource_class('Bundle::Entry::Request::METADATA')['method']['valid_codes'].values.first.include?(method.upcase)
                                 method.upcase
                               else
                                 'POST'
                               end
        request.ifNoneExist = if_none_exist unless if_none_exist.nil?
        if url.nil? && !resource.nil?
          options = {}
          options[:resource] = resource.class
          options[:id] = resource.id if request.local_method != 'POST'
          request.url = resource_url(options)
          request.url = request.url[1..-1] if request.url.starts_with?('/')
        else
          request.url = url
        end

        entry = versioned_resource_class('Bundle::Entry').new
        entry.resource = resource
        entry.request = request

        @transaction_bundle.entry << entry
        entry
      end

      # syntactic sugar for end_batch
      def end_transaction(format = @default_format)
        end_batch(format)
      end

      # submit the batch/transaction to the server
      # @param format
      # @return FHIR::ClientReply
      #
      def end_batch(format = @default_format)
        headers = {prefer: FHIR::Formats::ReturnPreferences::REPRESENTATION}
        headers[:content_type] =  "#{format}"
        options = { format: format}
        reply = post resource_url(options), @transaction_bundle, fhir_headers(headers)
        begin
          reply.resource = if format.downcase.include?('xml')
                             versioned_resource_class('Xml').from_xml(reply.body)
                           else
                             versioned_resource_class('Json').from_json(reply.body)
                           end
        rescue
          reply.resource = nil
        end
        set_client_on_resource(reply.resource)
        reply.resource_class = reply.resource.class
        reply
      end
    end
  end
end
