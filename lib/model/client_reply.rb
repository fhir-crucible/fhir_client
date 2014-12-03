module FHIR
  class ClientReply
    attr_accessor :request  # .args, .cookies, .headers, .method, .payload, .processed_headers, .url
    attr_accessor :response # .code, .cookies, .description, .headers, .raw_headers
    attr_accessor :resource # a FHIR resource
    attr_accessor :resource_class # class of the :resource

    def initialize(request, response)
      @request = request
      @response = response
    end

    def code
      @response.code unless @response.nil?
    end

    def id
      return nil if @resource_class.nil?
      (self_link || @request.url) =~ %r{(?<=#{@resource_class.name.demodulize}\/)(\w+)}
      $1
    end

    def version
      self_link =~ %r{(?<=_history\/)(\w+)}
      $1
    end

    def self_link
      (@response.headers[:content_location] || @response.headers[:location]) unless @response.nil? || @response.headers.nil?
    end

    def body
      @response.to_s unless @response.nil?
    end

  end
end