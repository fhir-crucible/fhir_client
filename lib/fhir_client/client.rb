require 'rest_client'
require 'nokogiri'
require 'addressable/uri'
require 'oauth2'
module FHIR
  class Client
    include FHIR::Sections::History
    include FHIR::Sections::Crud
    include FHIR::Sections::Tags
    include FHIR::Sections::Feed
    include FHIR::Sections::Search
    include FHIR::Sections::Operations
    include FHIR::Sections::Transactions
    include FHIR::VersionManagement

    attr_accessor :reply
    attr_accessor :use_format_param
    attr_accessor :use_basic_auth
    attr_accessor :use_oauth2_auth
    attr_accessor :security_headers
    attr_accessor :client

    attr_accessor :default_format
    attr_accessor :fhir_version
    attr_accessor :cached_capability_statement
    attr_accessor :additional_headers
    attr_accessor :proxy
    attr_accessor :exception_class

    attr_accessor :use_accept_header
    attr_accessor :use_accept_charset
    attr_accessor :use_return_preference

    # Call method to initialize FHIR client. This method must be invoked
    # with a valid base server URL prior to using the client.
    #
    # @param base_service_url Base service URL for FHIR Service.
    # @param default_format Default Format Mime type
    # @return
    #
    def initialize(base_service_url, default_format: FHIR::Formats::ResourceFormat::RESOURCE_JSON, proxy: nil)
      @base_service_url = base_service_url
      FHIR.logger.info "Initializing client with #{@base_service_url}"
      @use_format_param = false
      @use_accept_header = true
      @use_accept_charset = true
      @default_format = default_format
      @fhir_version = :r4
      @use_return_preference = false
      @return_preference = FHIR::Formats::ReturnPreferences::REPRESENTATION
      @exception_class = ClientException
      @proxy = proxy

      set_no_auth
    end

    def default_json
      @default_format = versioned_format_class(:json)
    end

    def default_xml
      @default_format = versioned_format_class(:xml)
    end

    def use_stu3
      @fhir_version = :stu3
      @default_format = versioned_format_class
    end

    def use_dstu2
      @fhir_version = :dstu2
      @default_format = versioned_format_class
    end

    def use_r4
      @fhir_version = :r4
      @default_format = versioned_format_class
    end

    #
    # Instructs the client to specify the minimal Prefer Header where applicable
    def use_minimal_preference
      @use_return_preference = true
      @return_preference = FHIR::Formats::ReturnPreferences::MINIMAL
    end

    #
    # Instructs the client to specify the representation Prefer Header where applicable
    def use_representation_preference
      @use_return_preference = true
      @return_preference = FHIR::Formats::ReturnPreferences::REPRESENTATION
    end

    def detect_version
      cap = capability_statement
      if cap.is_a?(FHIR::CapabilityStatement)
        use_r4
      elsif cap.is_a?(FHIR::STU3::CapabilityStatement)
        use_stu3
      elsif cap.is_a?(FHIR::DSTU2::Conformance)
        use_dstu2
      else
        use_r4
      end
      # Should update the default_format when changing fhir_version
      @default_format = versioned_format_class
      FHIR.logger.info("Detecting server FHIR version as #{@fhir_version} via metadata")
      @fhir_version
    end

    # Set the client to use no authentication mechanisms
    def set_no_auth
      FHIR.logger.info 'Configuring the client to use no authentication.'
      @use_oauth2_auth = false
      @use_basic_auth = false
      @security_headers = {}
      @client = RestClient
      @client.proxy = proxy unless proxy.nil?
      @client
    end

    # Set the client to use HTTP Basic Authentication
    def set_basic_auth(client, secret)
      FHIR.logger.info 'Configuring the client to use HTTP Basic authentication.'
      token = Base64.encode64("#{client}:#{secret}")
      value = "Basic #{token}"
      @security_headers = { 'Authorization' => value }
      @use_oauth2_auth = false
      @use_basic_auth = true
      @client = RestClient
      @client.proxy = proxy unless proxy.nil?
      @client
    end

    # Set the client to use Bearer Token Authentication
    def set_bearer_token(token)
      FHIR.logger.info 'Configuring the client to use Bearer Token authentication.'
      value = "Bearer #{token}"
      @security_headers = { 'Authorization' => value }
      @use_oauth2_auth = false
      @use_basic_auth = true
      @client = RestClient
      @client.proxy = proxy unless proxy.nil?
      @client
    end

    # Set the client to use OpenID Connect OAuth2 Authentication
    # client -- client id
    # secret -- client secret
    # authorize_path -- absolute path of authorization endpoint
    # token_path -- absolute path of token endpoint
    def set_oauth2_auth(client, secret, authorize_path, token_path, site = nil)
      FHIR.logger.info 'Configuring the client to use OpenID Connect OAuth2 authentication.'
      @use_oauth2_auth = true
      @use_basic_auth = false
      @security_headers = {}
      options = {
        site: site || @base_service_url,
        authorize_url: authorize_path,
        token_url: token_path,
        raise_errors: true
      }
      client = OAuth2::Client.new(client, secret, options)
      client.connection.proxy(proxy) unless proxy.nil?
      @client = client.client_credentials.get_token
    end

    # Get the OAuth2 server and endpoints from the capability statement
    # (the server should not require OAuth2 or other special security to access
    # the capability statement).
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
    def get_oauth2_metadata_from_conformance(strict=true)
      options = {
        authorize_url: nil,
        token_url: nil
      }
      begin
        capability_statement.rest.each do |rest|
          if strict
            rest.security.service.each do |service|
              service.coding.each do |coding|
                next unless coding.code == 'SMART-on-FHIR'
                 options.merge! get_oauth2_metadata_from_service_definition(rest)
              end
            end
          else
            options.merge! get_oauth2_metadata_from_service_definition(rest)
          end
        end
      rescue => e
        FHIR.logger.error "Failed to locate SMART-on-FHIR OAuth2 Security Extensions: #{e.message}"
      end
      options.delete_if { |_k, v| v.nil? }
      options.clear if options.keys.size != 2
      options
    end

    def get_oauth2_metadata_from_service_definition(rest)
      oauth_extension = 'http://fhir-registry.smarthealthit.org/StructureDefinition/oauth-uris'
      authorize_extension = 'authorize'
      token_extension = 'token'
      options = {
        authorize_url: nil,
        token_url: nil
      }
      rest.security.extension.find{|x| x.url == oauth_extension}.extension.each do |ext|
        case ext.url
        when authorize_extension
          options[:authorize_url] = ext.value
        when "#{oauth_extension}\##{authorize_extension}"
          options[:authorize_url] = ext.value
        when token_extension
          options[:token_url] = ext.value
        when "#{oauth_extension}\##{token_extension}"
          options[:token_url] = ext.value
        end
      end
      options
    end

    # Method returns a capability statement for the system queried.
    def capability_statement(format = @default_format)
      conformance_statement(format)
    end

    # Method returns a conformance statement for the system queried.
    # @return
    def conformance_statement(format = @default_format)
      if @cached_capability_statement.nil? || format != @default_format
        try_conformance_formats(format)
      end
      @cached_capability_statement
    end

    def try_conformance_formats(default_format)
      formats = [FHIR::Formats::ResourceFormat::RESOURCE_XML,
                 FHIR::Formats::ResourceFormat::RESOURCE_JSON,
                 FHIR::Formats::ResourceFormat::RESOURCE_XML_DSTU2,
                 FHIR::Formats::ResourceFormat::RESOURCE_JSON_DSTU2,
                 'application/xml',
                 'application/json']
      formats.insert(0, default_format)

      @cached_capability_statement = nil

      formats.each do |frmt|
        reply = get 'metadata', fhir_headers({accept: "#{frmt}"})
        next unless reply.code == 200
        use_r4
        begin
          @cached_capability_statement = parse_reply(FHIR::CapabilityStatement, frmt, reply)
        rescue
          @cached_capability_statement = nil
        end
        if @cached_capability_statement.nil? || !@cached_capability_statement.fhirVersion.starts_with?('4')
          use_stu3
          begin
            @cached_capability_statement = parse_reply(FHIR::STU3::CapabilityStatement, frmt, reply)
          rescue
            @cached_capability_statement = nil
          end
          unless @cached_capability_statement
            use_dstu2
            begin
              @cached_capability_statement = parse_reply(FHIR::DSTU2::Conformance, frmt, reply)
            rescue
              @cached_capability_statement = nil
            end
          end
        end
        if @cached_capability_statement
          @default_format = frmt
          break
        end
      end
      @default_format = default_format if @default_format.nil?
      @default_format
    end

    def resource_url(options)
      FHIR::ResourceAddress.resource_url(options, @use_format_param)
    end

    def full_resource_url(options)
      @base_service_url + resource_url(options)
    end

    def fhir_headers(options = {})
      FHIR::ResourceAddress.fhir_headers(options, additional_headers, @default_format, @use_accept_header, @use_accept_charset)
    end

    def parse_reply(klass, format, response)
      FHIR.logger.debug "Parsing response with {klass: #{klass}, format: #{format}, code: #{response.code}}."
      return nil unless [200, 201].include? response.code
      res = nil
      begin
        res = if(@fhir_version == :dstu2 || klass&.ancestors&.include?(FHIR::DSTU2::Model))
                if(format.include?('xml'))
                  FHIR::DSTU2::Xml.from_xml(response.body)
                else
                  FHIR::DSTU2::Json.from_json(response.body)
                end
              elsif(@fhir_version == :r4 || klass&.ancestors&.include?(FHIR::Model))
                if(format.include?('xml'))
                  FHIR::Xml.from_xml(response.body)
                else
                  FHIR::Json.from_json(response.body)
                end
              else
                if(format.include?('xml'))
                  FHIR::STU3::Xml.from_xml(response.body)
                else
                  FHIR::STU3::Json.from_json(response.body)
                end
              end
        res.client = self unless res.nil?
      rescue => e
        FHIR.logger.error "Failed to parse #{format} as resource #{klass}: #{e.message}"
        res = nil
      end
      res
    end

    def strip_base(path)
      path.gsub(@base_service_url, '')
    end

    def reissue_request(request)
      if [:get, :delete, :head].include?(request['method'])
        method(request['method']).call(request['url'], request['headers'])
      elsif [:post, :put].include?(request['method'])
        unless request['payload'].nil?
          resource = versioned_resource_class.from_contents(request['payload'])
        end
        method(request['method']).call(request['url'], resource, request['headers'])
      end
    end

    private

    def base_path(path)
      if path.start_with?('/')
        if @base_service_url.end_with?('/')
          @base_service_url.chop
        else
          @base_service_url
        end
      else
        @base_service_url + '/'
      end
    end

    # Extract the request payload in the specified format, defaults to XML
    def request_payload(resource, headers)
      if headers
        format_specified = headers['Content-Type']
        if format_specified.nil?
          resource.to_xml
        elsif format_specified.downcase.include?('xml')
          resource.to_xml
        elsif format_specified.downcase.include?('json')
          resource.to_json
        else
          resource.to_xml
        end
      else
        resource.to_xml
      end
    end

    def request_patch_payload(patchset, format)
      if format == FHIR::Formats::PatchFormat::PATCH_JSON
        patchset.each do |patch|
          # remove the resource name from the patch path, since the JSON representation doesn't have that
          patch[:path] = patch[:path].slice(patch[:path].index('/')..-1)
        end
        patchset.to_json
      elsif format == FHIR::Formats::PatchFormat::PATCH_XML
        builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
          patchset.each do |patch|
            xml.diff do
              # TODO: support other kinds besides just replace
              xml.replace(patch[:value], sel: patch[:path] + '/@value') if patch[:op] == 'replace'
            end
          end
        end
        builder.to_xml
      end
    end

    def clean_headers(headers)
      headers.delete_if { |k, v| (k.nil? || v.nil?) }
      FHIR::ResourceAddress.convert_symbol_headers(headers)
    end

    def get(path, headers = {})
      request :get, path, headers
    end

    def post(path, resource, headers)
      request :post, path, headers, resource
    end

    def put(path, resource, headers)
      request :put, path, headers, resource
    end

    def patch(path, resource, headers)
      request :patch, path, headers, resource
    end

    def delete(path, headers = {})
      request :delete, path, headers
    end

    def head(path, headers)
      request :head, path, headers
    end
    
    def request(action, path, headers, resource = nil)
      # Grab the name of the class
      # If 
      module_name = @client.class
      module_name = @client if [Object, Module].include? module_name
      resolver    = FHIR::Client::RestProviders.const_get(module_name.to_s)

      url = Addressable::URI.parse(build_url(path)).to_s
      FHIR.logger.info "#{action.to_s.upcase} #{url}"

      headers = clean_headers(headers) unless headers.empty?
      case action
      when :patch
        payload = request_patch_payload(resource, headers['Content-Type'])
      else
        payload = request_payload(resource, headers) if resource
      end
      @reply = resolver.request action, self, url,
                    base_service_url: @base_service_url,
                    credentials: @security_headers,
                    headers: headers,
                    body: payload
    end

    def build_url(path)
      if /^\w+:\/\//.match? path
        path
      else
        "#{base_path(path)}#{path}"
      end
    end
  end
end
