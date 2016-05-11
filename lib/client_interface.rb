module FHIR

  class Client

    include FHIR::Sections::History
    include FHIR::Sections::Crud
    include FHIR::Sections::Validate
    include FHIR::Sections::Tags
    include FHIR::Sections::Feed
    include FHIR::Sections::Search
    include FHIR::Sections::Operations
    include FHIR::Sections::Transactions

    attr_accessor :reply
    attr_accessor :use_format_param
    attr_accessor :use_basic_auth
    attr_accessor :use_oauth2_auth
    attr_accessor :security_headers
    attr_accessor :client

    attr_accessor :default_format
    attr_accessor :default_format_bundle

    attr_accessor :cached_conformance

  # Call method to initialize FHIR client. This method must be invoked
  # with a valid base server URL prior to using the client.
  #
  # @param baseServiceUrl Base service URL for FHIR Service.
  # @return
  #
  def initialize(baseServiceUrl)
    $LOG.info "Initializing client with #{@baseServiceUrl}"
    @baseServiceUrl = baseServiceUrl
    @use_format_param = false
    @default_format = FHIR::Formats::ResourceFormat::RESOURCE_XML
    @default_format_bundle = FHIR::Formats::FeedFormat::FEED_XML
    set_no_auth
  end

  # Set the client to use no authentication mechanisms
  def set_no_auth
    $LOG.info "Configuring the client to use no authentication."
    @use_oauth2_auth = false
    @use_basic_auth = false
    @security_headers = {}
    @client = RestClient
  end

  # Set the client to use HTTP Basic Authentication
  def set_basic_auth(client,secret)
    $LOG.info "Configuring the client to use HTTP Basic authentication."
    token = Base64.encode64("#{client}:#{secret}")
    value = "Basic #{token}"
    @security_headers = { 'Authorization' => value }
    @use_oauth2_auth = false
    @use_basic_auth = true
    @client = RestClient
  end

  # Set the client to use Bearer Token Authentication
  def set_bearer_token(token)
    $LOG.info "Configuring the client to use Bearer Token authentication."
    value = "Bearer #{token}"
    @security_headers = { 'Authorization' => value }
    @use_oauth2_auth = false
    @use_basic_auth = true
    @client = RestClient
  end

  # Set the client to use OpenID Connect OAuth2 Authentication
  # client -- client id
  # secret -- client secret
  # authorizePath -- absolute path of authorization endpoint
  # tokenPath -- absolute path of token endpoint
  def set_oauth2_auth(client,secret,authorizePath,tokenPath)
    $LOG.info "Configuring the client to use OpenID Connect OAuth2 authentication."
    @use_oauth2_auth = true
    @use_basic_auth = false
    @security_headers = {}
    options = {
      :site => @baseServiceUrl,
      :authorize_url => authorizePath,
      :token_url => tokenPath,
      :raise_errors => true
    }
    client = OAuth2::Client.new(client,secret,options)
    @client = client.client_credentials.get_token
  end

  # Get the OAuth2 server and endpoints from the conformance statement
  # (the server should not require OAuth2 or other special security to access
  # the conformance statement).
  # <rest>
  #   <mode value="server"/>
  #   <documentation value="All the functionality defined in FHIR"/>
  #   <security>
  #   <extension url="http://fhir-registry.smarthealthit.org/StructureDefinition/oauth-uris">
  #     <extension url="register">
  #       <valueUri value="https://authorize-dstu2.smarthealthit.org/register"/>
  #     </extension>
  #     <extension url="authorize">
  #       <valueUri value="https://authorize-dstu2.smarthealthit.org/authorize"/>
  #     </extension>
  #     <extension url="token">
  #       <valueUri value="https://authorize-dstu2.smarthealthit.org/token"/>
  #     </extension>
  #   </extension>
  #   <service>
  #     <coding>
  #       <system value="http://hl7.org/fhir/vs/restful-security-service"/>
  #       <code value="OAuth2"/>
  #     </coding>
  #     <text value="OAuth version 2 (see oauth.net)."/>
  #   </service>
  #   <description value="SMART on FHIR uses OAuth2 for authorization"/>
  # </security>
  def get_oauth2_metadata_from_conformance
    options = {
      :authorize_url => nil,
      :token_url => nil
    }
    oauth_extension = 'http://fhir-registry.smarthealthit.org/StructureDefinition/oauth-uris'
    authorize_extension = 'authorize'
    token_extension = 'token'
    begin
      conformance = conformanceStatement
      conformance.rest.each do |rest|
        rest.security.service.each do |service|
          service.coding.each do |coding|
            if coding.code == 'SMART-on-FHIR'
              rest.security.extension.where({url: oauth_extension}).first.extension.each do |ext|
                case ext.url
                when authorize_extension
                  options[:authorize_url] = ext.value.value
                when "#{oauth_extension}\##{authorize_extension}"
                  options[:authorize_url] = ext.value.value
                when token_extension
                  options[:token_url] = ext.value.value
                when "#{oauth_extension}\##{token_extension}"
                  options[:token_url] = ext.value.value
                end
              end
            end
          end
        end
      end
    rescue Exception => e
      $LOG.error 'Failed to locate SMART-on-FHIR OAuth2 Security Extensions.'
    end
    options.delete_if{|k,v|v.nil?}
    options.clear if options.keys.size!=2
    options
  end

  # Method returns a conformance statement for the system queried.
  # @return
  def conformanceStatement(format=FHIR::Formats::ResourceFormat::RESOURCE_XML)
    if (@cached_conformance.nil? || format!=@default_format)
      format = try_conformance_formats(format)
    end
    @cached_conformance
  end

  def try_conformance_formats(default_format)
    formats = [ FHIR::Formats::ResourceFormat::RESOURCE_XML,
      FHIR::Formats::ResourceFormat::RESOURCE_JSON,
      'application/xml',
      'application/json']
    formats.insert(0,default_format)

    @cached_conformance = nil
    @default_format = nil
    @default_format_bundle = nil

    formats.each do |frmt|
      reply = get 'metadata', fhir_headers({format: frmt})
      if reply.code == 200
        @cached_conformance = parse_reply(FHIR::Conformance, frmt, reply)
        @default_format = frmt
        @default_format_bundle = frmt
        break
      end
    end
    @default_format = default_format if @default_format.nil?
    @default_format
  end

  def resource_url(options)
    FHIR::ResourceAddress.new.resource_url(options, @use_format_param)
  end

  def full_resource_url(options)
    @baseServiceUrl + resource_url(options)
  end

  def fhir_headers(options={})
    FHIR::ResourceAddress.new.fhir_headers(options, @use_format_param)
  end

  def parse_reply(klass, format, response)
    $LOG.info "Parsing response with {klass: #{klass}, format: #{format}, code: #{response.code}}."
    return nil if ![200,201].include? response.code
    res = nil
    begin
      res = nil
      if(format.downcase.include?('xml'))
        res = FHIR::Xml.from_xml(response.body)
      else
        res = FHIR::Json.from_json(response.body)
      end
      $LOG.warn "Expected #{klass} but got #{res.class}" if res.class!=klass
    rescue Exception => e
      $LOG.error "Failed to parse #{format} as resource #{klass}: #{e.message} %n #{e.backtrace.join("\n")} #{response}"
      nil
    end
    res
  end

  def strip_base(path)
    path.gsub(@baseServiceUrl, '')
  end

  def reissue_request(request)
    if [:get, :delete, :head].include?(request['method'])
      method(request['method']).call(request['url'], request['headers'])
    elsif [:post, :put].include?(request['method'])
      resource = request['headers']['resource'].constantize.from_xml(request['payload'])
      method(request['method']).call(request['url'], resource, request['headers'])
    end
  end

  private

    def base_path(path)
      if path.start_with?('/')
        if @baseServiceUrl.end_with?('/')
          @baseServiceUrl.chop
        else
          @baseServiceUrl
        end
      else
        @baseServiceUrl + '/'
      end
    end

    # Extract the request payload in the specified format, defaults to XML
    def request_payload(resource, headers)
      if headers
        case headers["format"]
        when FHIR::Formats::ResourceFormat::RESOURCE_XML
          resource.to_xml
        when FHIR::Formats::ResourceFormat::RESOURCE_JSON
          resource.to_json
        else
          resource.to_xml
        end
      else
        resource.to_xml
      end
    end

    def clean_headers(headers)
      headers.delete_if{|k,v|(k.nil? || v.nil?)}
      headers.inject({}){|h,(k,v)| h[k.to_s]=v.to_s; h}
    end

    def scrubbed_response_headers(result)
      result.each_key do |k|
        v = result[k]
        result[k] = v[0] if (v.is_a? Array)
      end
    end

    def get(path, headers)
      url = URI(build_url(path)).to_s
      $LOG.info "GETTING: #{url}"
      headers = clean_headers(headers)
      if @use_oauth2_auth
        # @client.refresh!
        begin
          response = @client.get(url, {:headers=>headers})
        rescue Exception => e
          response = e.response if e.response
        end
        req = {
          :method => :get,
          :url => url,
          :headers => headers,
          :payload => nil
        }
        res = {
          :code => response.status.to_s,
          :headers => response.headers,
          :body => response.body
        }
        $LOG.info "GET - Request: #{req.to_s}, Response: #{response.body.force_encoding("UTF-8")}"
        @reply = FHIR::ClientReply.new(req, res)
      else
        headers.merge!(@security_headers) if @use_basic_auth
        @client.get(url, headers){ |response, request, result|
          $LOG.info "GET - Request: #{request.to_json}, Response: #{response.force_encoding("UTF-8")}"
          res = {
            :code => result.code,
            :headers => scrubbed_response_headers(result.each_key{}),
            :body => response
          }
          @reply = FHIR::ClientReply.new(request.args, res)
        }
      end
    end

    def post(path, resource, headers)
      url = URI(build_url(path)).to_s
      puts "POSTING: #{url}"
      headers = clean_headers(headers)
      payload = request_payload(resource, headers) if resource
      if @use_oauth2_auth
        # @client.refresh!
        begin
          response = @client.post(url, {:headers=>headers,:body=>payload})
        rescue Exception => e
          response = e.response if e.response
        end
        req = {
          :method => :post,
          :url => url,
          :headers => headers,
          :payload => payload
        }
        res = {
          :code => response.status.to_s,
          :headers => response.headers,
          :body => response.body
        }
        $LOG.info "POST - Request: #{req.to_s}, Response: #{response.body.force_encoding("UTF-8")}"
        @reply = FHIR::ClientReply.new(req, res)
      else
        headers.merge!(@security_headers) if @use_basic_auth
        @client.post(url, payload, headers){ |response, request, result|
          $LOG.info "POST - Request: #{request.to_json}, Response: #{response.force_encoding("UTF-8")}"
          res = {
            :code => result.code,
            :headers => scrubbed_response_headers(result.each_key{}),
            :body => response
          }
          @reply = FHIR::ClientReply.new(request.args, res)
        }
      end
    end

    def put(path, resource, headers)
      url = URI(build_url(path)).to_s
      puts "PUTTING: #{url}"
      headers = clean_headers(headers)
      payload = request_payload(resource, headers) if resource
      if @use_oauth2_auth
        # @client.refresh!
        begin
          response = @client.put(url, {:headers=>headers,:body=>payload})
        rescue Exception => e
          response = e.response if e.response
        end
        req = {
          :method => :put,
          :url => url,
          :headers => headers,
          :payload => payload
        }
        res = {
          :code => response.status.to_s,
          :headers => response.headers,
          :body => response.body
        }
        $LOG.info "PUT - Request: #{req.to_s}, Response: #{response.body.force_encoding("UTF-8")}"
        @reply = FHIR::ClientReply.new(req, res)
      else
        headers.merge!(@security_headers) if @use_basic_auth
        @client.put(url, payload, headers){ |response, request, result|
          $LOG.info "PUT - Request: #{request.to_json}, Response: #{response.force_encoding("UTF-8")}"
          res = {
            :code => result.code,
            :headers => scrubbed_response_headers(result.each_key{}),
            :body => response
          }
          @reply = FHIR::ClientReply.new(request.args, res)
        }
      end
    end

    def delete(path, headers)
      url = URI(build_url(path)).to_s
      puts "DELETING: #{url}"
      headers = clean_headers(headers)
      if @use_oauth2_auth
        # @client.refresh!
        begin
          response = @client.delete(url, {:headers=>headers})
        rescue Exception => e
          response = e.response if e.response
        end
        req = {
          :method => :delete,
          :url => url,
          :headers => headers,
          :payload => nil
        }
        res = {
          :code => response.status.to_s,
          :headers => response.headers,
          :body => response.body
        }
        $LOG.info "DELETE - Request: #{req.to_s}, Response: #{response.body.force_encoding("UTF-8")}"
        @reply = FHIR::ClientReply.new(req, res)
      else
        headers.merge!(@security_headers) if @use_basic_auth
        @client.delete(url, headers){ |response, request, result|
          $LOG.info "DELETE - Request: #{request.to_json}, Response: #{response.force_encoding("UTF-8")}"
          res = {
            :code => result.code,
            :headers => scrubbed_response_headers(result.each_key{}),
            :body => response
          }
          @reply = FHIR::ClientReply.new(request.args, res)
        }
      end
    end

    def head(path, headers)
      headers.merge!(@security_headers) unless @security_headers.blank?
      url = URI(build_url(path)).to_s
      puts "HEADING: #{url}"
      RestClient.head(url, headers){ |response, request, result|
        $LOG.info "HEAD - Request: #{request.to_json}, Response: #{response.force_encoding("UTF-8")}"
        res = {
          :code => result.code,
          :headers => scrubbed_response_headers(result.each_key{}),
          :body => response
        }
        @reply = FHIR::ClientReply.new(request.args, res)
      }
    end

    def build_url(path)
      if path =~ /^\w+:\/\//
        path
      else
        "#{base_path(path)}#{path}"
      end
    end

  end

end
