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
      if !@response.nil?
        return @response.code
      end
      nil
    end

    def id
      if @resource_class.nil?
        return nil
      end

      if !@response.nil? and !@response.headers.nil? and !@response.headers[:location].nil?
        @response.headers[:location] =~ %r{(?<=#{@resource_class.name.demodulize}\/)(\w+)}
      else 
        @request.url =~ %r{(?<=#{@resource_class.name.demodulize}\/)(\w+)}
      end
      $1
    end

    def version
      if !@response.nil? and !@response.headers.nil? and !@response.headers[:location].nil?
        @response.headers[:location] =~ %r{(?<=_history\/)(\w+)}
        return $1
      end
      nil
    end

    def body
      if !@response.nil?
        return @response.to_s
      end
      nil
    end

  end
end