module FHIR

  class Client

    include FHIR::Sections::History
    include FHIR::Sections::Crud
    include FHIR::Sections::Validate
    include FHIR::Sections::Tags
    include FHIR::Sections::Feed
    include FHIR::Sections::Search
    include FHIR::Sections::Operations

    attr_accessor :reply
    attr_accessor :use_format_param
    attr_accessor :use_basic_auth
    attr_accessor :use_oauth2_auth
    attr_accessor :security_headers
    attr_accessor :client

    attr_accessor :default_format
    attr_accessor :default_format_bundle

    attr_accessor :cached_conformance

  # public interface VersionInfo {
  #   public String getClientJavaLibVersion();
  #   public String getFhirJavaLibVersion();
  #   public String getFhirJavaLibRevision();
  #   public String getFhirServerVersion();
  #   public String getFhirServerSoftware();
 #  }

  #
  # Get the Java verion of client and reference implementation, the
  # client FHIR version, the server FHIR version, and the server
  # software version. The server information will be blank if no
  # service URL is provided
  #
  # @return the version information
  #
  # public VersionInfo getVersions();


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
      :authorize_url => authorizePath,
      :token_url => tokenPath,
      :raise_errors => false
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
  #     <extension url="http://fhir-registry.smarthealthit.org/StructureDefinition/oauth-uris#register">
  #       <valueUri value="http://example:8080/openid-connect-server-webapp/register"/>
  #     </extension>
  #     <extension url="http://fhir-registry.smarthealthit.org/StructureDefinition/oauth-uris#authorize">
  #       <valueUri value="http://example:8080/openid-connect-server-webapp/authorize"/>
  #     </extension>
  #     <extension url="http://fhir-registry.smarthealthit.org/StructureDefinition/oauth-uris#token">
  #       <valueUri value="http://example:8080/openid-connect-server-webapp/token"/>
  #     </extension>
  #     <service>
  #       <coding>
  #         <system value="http://hl7.org/fhir/vs/restful-security-service"/>
  #         <code value="OAuth2"/>
  #       </coding>
  #       <text value="OAuth version 2 (see oauth.net)."/>
  #     </service>
  #     <description value="SMART on FHIR uses OAuth2 for authorization"/>
  #   </security>
  def get_oauth2_metadata_from_conformance
    options = {
      :authorize_url => nil,
      :token_url => nil
    }
    authorize_extension = 'http://fhir-registry.smarthealthit.org/StructureDefinition/oauth-uris#authorize'
    token_extension = 'http://fhir-registry.smarthealthit.org/StructureDefinition/oauth-uris#token'
 
    begin
      conformance = conformanceStatement
      conformance.rest.each do |rest|
        rest.security.service.each do |service|
          service.coding.each do |coding|
            if coding.code == 'OAuth2'
              rest.security.extension.where({url: "http://fhir-registry.smarthealthit.org/StructureDefinition/oauth-uris"}).first.extension.each do |ext|
                case ext.absolute_url
                when authorize_extension
                  options[:authorize_url] = ext.value[:value]
                when token_extension
                  options[:token_url] = ext.value[:value]
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

  #
  #
  # Call method to initialize FHIR client. This method must be invoked
  # with a valid base server URL prior to using the client.
  #
  # Invalid base server URLs will result in a URISyntaxException being thrown.
  #
  # @param baseServiceUrl The base service URL
  # @param resultCount Maximum size of the result set
  # @throws URISyntaxException
  #
  # public void initialize(String baseServiceUrl, int recordCount)  throws URISyntaxException;

  #
  # Override the default resource format of 'application/fhir+xml'. This format is
  # used to set Accept and Content-Type headers for client requests.
  #
  # @param resourceFormat
  #
  # public void setPreferredResourceFormat(ResourceFormat resourceFormat);

  #
  # Returns the resource format in effect.
  #
  # @return
  #
  # public String getPreferredResourceFormat();

  #
  # Override the default feed format of 'application/atom+xml'. This format is
  # used to set Accept and Content-Type headers for client requests.
  #
  # @param resourceFormat
  #
  # public void setPreferredFeedFormat(FeedFormat feedFormat);

  #
  # Returns the feed format in effect.
  #
  # @return
  #
  # public String getPreferredFeedFormat();

  #
  # Returns the maximum record count specified for list operations
  # such as search and history.
  #
  # @return
  #
  # public int getMaximumRecordCount();

  #
  # Sets the maximum record count for list operations such as history
  # and search.
  #  *
  # @param recordCount
  #
  # public void setMaximumRecordCount(int recordCount);

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

  #
  # Method returns a conformance statement for the system queried.
  #
  # @param useOptionsVerb If 'true', use OPTION rather than GET.
  #
  # @return
  #
  # public Conformance getConformanceStatement(boolean useOptionsVerb);


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
      res = FHIR::Resource.from_contents(response.body)
      $LOG.warn "Expected #{klass} but got #{res.class}" if res.class!=klass
    rescue Exception => e
      $LOG.error "Failed to parse #{format} as resource #{klass}: #{e.message} %n #{e.backtrace.join("\n")} #{response}"
      nil
    end
    res
  end

  #
  # Return all results matching search query parameters for the given resource class.
  #
  # @param resourceClass
  # @param params
  # @return
  #
  # public <T extends Resource> AtomFeed search(Class<T> resourceClass, Map<String, String> params);

 #  /**
 #   * Return all results matching search query parameters for the given resource class.
 #   * This includes a resource as one of the parameters, and performs a post
 #   *
 #   * @param resourceClass
 #   * @param params
 #   * @return
 #   */
 #  public <T extends Resource> AtomFeed searchPost(Class<T> resourceClass, T resource, Map<String, String> params);

  #
  # Update or create a set of resources
  #
  # @param batch
  # @return
  #
  # public AtomFeed transaction(AtomFeed batch);


  #
  # Use this to follow a link found in a feed (e.g. paging in a search)
  #
  # @param link - the URL provided by the server
  # @return the feed the server returns
  #
  # public AtomFeed fetchFeed(String url);


  #
  #  invoke the expand operation and pass the value set for expansion
  #
  # @param source
  # @return
  # @throws Exception
  #
 #  public ValueSet expandValueset(ValueSet source) throws Exception;

    private

    def base_path(path)
      if path.starts_with?('/')
        if @baseServiceUrl.end_with?('/')
          @baseServiceUrl.chop
        else
          @baseServiceUrl
        end
      else
        @baseServiceUrl + '/'
      end
    end

    def strip_base(path)
      path.gsub(@baseServiceUrl, '')
    end

    # Extract the request payload in the specified format, defaults to XML
    def request_payload(resource, headers)
      if headers
        case headers[:format]
        when FHIR::Formats::ResourceFormat::RESOURCE_XML
          resource.to_xml
        when FHIR::Formats::ResourceFormat::RESOURCE_JSON
          resource.to_fhir_json
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
      puts "GETTING: #{base_path(path)}#{path}"
      headers = clean_headers(headers)
      url = URI("#{base_path(path)}#{path}").to_s
      if @use_oauth2_auth
        # @client.refresh!
        response = @client.get(url, {:headers=>headers})
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
      puts "POSTING: #{base_path(path)}#{path}"
      headers = clean_headers(headers)
      url = URI("#{base_path(path)}#{path}").to_s
      payload = request_payload(resource, headers) if resource
      if @use_oauth2_auth
        # @client.refresh!
        response = @client.post(url, {:headers=>headers,:body=>payload})
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
      puts "PUTTING: #{base_path(path)}#{path}"
      headers = clean_headers(headers)
      url = URI("#{base_path(path)}#{path}").to_s
      payload = request_payload(resource, headers) if resource
      if @use_oauth2_auth
        # @client.refresh!
        response = @client.put(url, {:headers=>headers,:body=>payload})
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
      puts "DELETING: #{base_path(path)}#{path}"
      headers = clean_headers(headers)
      url = URI("#{base_path(path)}#{path}").to_s
      if @use_oauth2_auth
        # @client.refresh!
        response = @client.delete(url, {:headers=>headers})
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
      puts "HEADING: #{base_path(path)}#{path}"
      RestClient.head(URI("#{base_path(path)}#{path}").to_s, headers){ |response, request, result|
        $LOG.info "HEAD - Request: #{request.to_json}, Response: #{response.force_encoding("UTF-8")}"
        res = {
          :code => result.code,
          :headers => scrubbed_response_headers(result.each_key{}),
          :body => response
        }
        @reply = FHIR::ClientReply.new(request.args, res)
      }
    end

  end

end
