module FHIR
  module Sections
    module Transactions

      attr_accessor :transaction_bundle

      def begin_transaction
        @transaction_bundle = FHIR::Bundle.new
        @transaction_bundle.fhirType = 'transaction'
        @transaction_bundle
      end

      def begin_batch
        @transaction_bundle = FHIR::Bundle.new
        @transaction_bundle.fhirType = 'batch'
        @transaction_bundle
      end

      # syntactic sugar for add_batch_request
      # @param method one of ['GET','POST','PUT','DELETE']
      # @param url relative path, such as 'Patient/123'. Do not include the [base]
      # @param resource The resource if a POST or PUT
      def add_transaction_request(method, url, resource=nil, if_none_exist=nil)
        add_batch_request(method, url, resource, if_none_exist)
      end

      def add_batch_request(method, url, resource=nil, if_none_exist=nil)
        request = FHIR::Bundle::BundleEntryRequestComponent.new
        if FHIR::Bundle::BundleEntryRequestComponent::VALID_CODES.include?(method.upcase)
          request.method = method.upcase 
        else
          request.method = 'POST'
        end
        request.ifNoneExist = if_none_exist if !if_none_exist.nil?
        if url.nil? && !resource.nil?
          options = Hash.new
          options[:resource] = resource.class
          options[:id] = resource.xmlId if request.method!='POST'
          request.url = resource_url(options)
          request.url = request.url[1..-1] if request.url.starts_with?('/')
        else
          request.url = url
        end

        entry = FHIR::Bundle::BundleEntryComponent.new
        entry.resource = resource
        entry.request = request

        @transaction_bundle.entry << entry
        entry
      end

      # syntactic sugar for end_batch
      def end_transaction(format=@default_format)
        end_batch(format)
      end

      # submit the batch/transaction to the server
      # @param format
      # @return FHIR::ClientReply
      #
      def end_batch(format=@default_format)
        options = { format: format }
        reply = post resource_url(options), @transaction_bundle, fhir_headers(options)
        begin
          reply.resource = FHIR::Resource.from_contents(reply.body)
        rescue Exception => e 
          reply.resource = @transaction_bundle # just send back the submitted resource
        end
        reply.resource_class = @transaction_bundle.class
        reply
      end

    end
  end
end

