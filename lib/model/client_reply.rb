module FHIR
  class ClientReply
    # {
    #   :method => :get,
    #   :url => 'http://bonfire.mitre.org/fhir/Patient/123/$everything',
    #   :headers => {},
    #   :payload => nil # body of request goes here in POST
    # }
    attr_accessor :request  
    # {
    #   :code => '200',
    #   :headers => {},
    #   :body => '{xml or json here}'
    # }
    attr_accessor :response 
    attr_accessor :resource # a FHIR resource
    attr_accessor :resource_class # class of the :resource

    def initialize(request, response)
      @request = request
      @response = response
    end

    def code
      @response[:code].to_i unless @response.nil?
    end

    def id
      return nil if @resource_class.nil?
      (self_link || @request[:url]) =~ %r{(?<=#{@resource_class.name.demodulize}\/)(\w+)}
      $1
    end

    def version
      self_link =~ %r{(?<=_history\/)(\w+)}
      $1
    end

    def self_link
      (@response[:headers][:content_location] || @response[:headers][:location]) unless @response.nil? || @response[:headers].nil?
    end

    def body
      @response[:body] unless @response.nil?
    end

  end
end