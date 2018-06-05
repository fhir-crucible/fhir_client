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

    attr_accessor :reply
    attr_accessor :use_format_param
    attr_accessor :use_basic_auth
    attr_accessor :use_oauth2_auth
    attr_accessor :security_headers
    attr_accessor :client

    attr_accessor :default_format
    attr_accessor :fhir_version
    attr_accessor :cached_capability_statement

    # Call method to initialize FHIR client. This method must be invoked
    # with a valid base server URL prior to using the client.
    #
    # @param base_service_url Base service URL for FHIR Service.
    # @param default_format Default Format Mime type
    # @return
    #
    def initialize(base_service_url, default_format: FHIR::Formats::ResourceFormat::RESOURCE_XML)
      @base_service_url = base_service_url
      FHIR.logger.info "Initializing client with #{@base_service_url}"
      @use_format_param = false
      @default_format = default_format
      @fhir_version = :stu3
      set_no_auth
    end

    def default_json
      @default_format = if @fhir_version == :stu3
                          FHIR::Formats::ResourceFormat::RESOURCE_JSON
                        else
                          FHIR::Formats::ResourceFormat::RESOURCE_JSON_DSTU2
                        end
    end

    def default_xml
      @default_format = if @fhir_version == :stu3
                          FHIR::Formats::ResourceFormat::RESOURCE_XML
                        else
                          FHIR::Formats::ResourceFormat::RESOURCE_XML_DSTU2
                        end
    end

    def use_stu3
      @fhir_version = :stu3
      @default_format = if @default_format.include?('xml')
                          FHIR::Formats::ResourceFormat::RESOURCE_XML
                        else
                          FHIR::Formats::ResourceFormat::RESOURCE_JSON
                        end
    end

    def use_dstu2
      @fhir_version = :dstu2
      @default_format = if @default_format.include?('xml')
                          FHIR::Formats::ResourceFormat::RESOURCE_XML_DSTU2
                        else
                          FHIR::Formats::ResourceFormat::RESOURCE_JSON_DSTU2
                        end
    end

    def versioned_resource_class(klass)
      if @fhir_version == :stu3
        FHIR.const_get(klass)
      else
        FHIR::DSTU2.const_get(klass)
      end
    end

    def detect_version
      cap = capability_statement
      if cap.is_a?(FHIR::CapabilityStatement)
        @fhir_version = :stu3
      elsif cap.is_a?(FHIR::DSTU2::Conformance)
        @fhir_version = :dstu2
      else
        @fhir_version = :stu3
      end
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
    end

    # Set the client to use Bearer Token Authentication
    def set_bearer_token(token)
      FHIR.logger.info 'Configuring the client to use Bearer Token authentication.'
      value = "Bearer #{token}"
      @security_headers = { 'Authorization' => value }
      @use_oauth2_auth = false
      @use_basic_auth = true
      @client = RestClient
    end

    # Set the client to use OpenID Connect OAuth2 Authentication
    # client -- client id
    # secret -- client secret
    # authorize_path -- absolute path of authorization endpoint
    # token_path -- absolute path of token endpoint
    def set_oauth2_auth(client, secret, authorize_path, token_path)
      FHIR.logger.info 'Configuring the client to use OpenID Connect OAuth2 authentication.'
      @use_oauth2_auth = true
      @use_basic_auth = false
      @security_headers = {}
      options = {
        site: @base_service_url,
        authorize_url: authorize_path,
        token_url: token_path,
        raise_errors: true
      }
      client = OAuth2::Client.new(client, secret, options)
      @client = client.client_credentials.get_token
    end

    # Enable OAuth authentication through the use of access and refresh tokens
    # client -- client id
    # secret -- client secret
    # options -- hash of options
    #   access_token: Current access_token
    #   refresh_token: a token that is used to obtain an new access_token when it
    #                  expires or does not currently exist
    #   authorize_path -- absolute path of authorization endpoint
    #   token_path -- absolute path of token endpoint
    #   auto_configure -- whether or not to configure the oauth endpoints from the servers capability statement
    #  Addtional options can be passed in as supported by the OAuth2::AccessToken class
    def set_auth_from_token(client, secret, options)
      FHIR.logger.info 'Configuring the client to use OAuth2 access token authentication.'

      raise  "Must provide an access_token or a refresh_token" if options[:access_token].nil? &&  options[:refresh_token].nil?
      token = options.delete(:access_token)
      auto_configure = options.delete(:auto_configure)
      client_options = {
        authorize_url: options.delete(:authorize_path),
        token_url: options.delete(:token_path)
      }
      client_options = get_oauth2_metadata_from_conformance(false) if auto_configure
      # dont set befor call to capability statement, it will fail
      @use_oauth2_auth = true
      @use_basic_auth = false
      @security_headers = {}

      client = OAuth2::Client.new(client, secret, client_options)

      access_token = OAuth2::AccessToken.new(client, token, options)
      @client = access_token
      if access_token.refresh_token && access_token.expired?
        @client = access_token.refresh!
      end
      @client
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
      @default_format = nil

      formats.each do |frmt|
        reply = get 'metadata', fhir_headers(format: frmt)
        next unless reply.code == 200
        begin
          @cached_capability_statement = parse_reply(FHIR::CapabilityStatement, frmt, reply)
        rescue
          @cached_capability_statement = nil
        end
        unless @cached_capability_statement
          begin
            @cached_capability_statement = parse_reply(FHIR::DSTU2::Conformance, frmt, reply)
          rescue
            @cached_capability_statement = nil
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
      FHIR::ResourceAddress.new.resource_url(options, @use_format_param)
    end

    def full_resource_url(options)
      @base_service_url + resource_url(options)
    end

    def fhir_headers(options = {})
      FHIR::ResourceAddress.new.fhir_headers(options, @use_format_param)
    end

    def parse_reply(klass, format, response)
      FHIR.logger.debug "Parsing response with {klass: #{klass}, format: #{format}, code: #{response.code}}."
      return nil unless [200, 201].include? response.code
      res = nil
      begin
        res = if(@fhir_version == :dstu2 || klass.ancestors.include?(FHIR::DSTU2::Model))
                if(format.include?('xml'))
                  FHIR::DSTU2::Xml.from_xml(response.body)
                else
                  FHIR::DSTU2::Json.from_json(response.body)
                end
              else
                if(format.include?('xml'))
                  FHIR::Xml.from_xml(response.body)
                else
                  FHIR::Json.from_json(response.body)
                end
              end
        res.client = self unless res.nil?
        FHIR.logger.warn "Expected #{klass} but got #{res.class}" if res.class != klass
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
          resource = if @fhir_version == :stu3
                       FHIR.from_contents(request['payload'])
                     else
                       FHIR::DSTU2.from_contents(request['payload'])
                     end
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
        format_specified = headers[:format] || headers['format']
        if format_specified.downcase.include?('xml')
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
      headers.each_with_object({}) { |(k, v), h| h[k.to_s] = v.to_s; h }
    end

    def scrubbed_response_headers(result)
      result.each_key do |k|
        v = result[k]
        result[k] = v[0] if v.is_a? Array
      end
    end

    def get(path, headers)
      url = Addressable::URI.parse(build_url(path)).to_s
      FHIR.logger.info "GETTING: #{url}"
      headers = clean_headers(headers)
      if @use_oauth2_auth
        # @client.refresh!
        begin
          response = @client.get(url, headers: headers)
        rescue => e
          unless e.response
            # Re-raise the client error if there's no response. Otherwise, logging
            # and other things break below!
            FHIR.logger.error "GET - Request: #{url} failed! No response from server: #{e}"
            raise # Re-raise the same error we caught.
          end
          response = e.response if e.response
        end
        req = {
          method: :get,
          url: url,
          path: url.gsub(@base_service_url, ''),
          headers: headers,
          payload: nil
        }
        res = {
          code: response.status.to_s,
          headers: response.headers,
          body: response.body
        }
        if url.end_with?('/metadata')
          FHIR.logger.debug "GET - Request: #{req}, Response: [too large]"
        else
          FHIR.logger.debug "GET - Request: #{req}, Response: #{response.body.force_encoding('UTF-8')}"
        end
        @reply = FHIR::ClientReply.new(req, res, self)
      else
        headers.merge!(@security_headers) if @use_basic_auth
        begin
          response = @client.get(url, headers)
        rescue RestClient::SSLCertificateNotVerified => sslerr
          FHIR.logger.error "SSL Error: #{url}"
          req = {
            method: :get,
            url: url,
            path: url.gsub(@base_service_url, ''),
            headers: headers,
            payload: nil
          }
          res = {
            code: nil,
            headers: nil,
            body: sslerr.message
          }
          @reply = FHIR::ClientReply.new(req, res, self)
          return @reply
        rescue => e
          unless e.response
            # Re-raise the client error if there's no response. Otherwise, logging
            # and other things break below!
            FHIR.logger.error "GET - Request: #{url} failed! No response from server: #{e}"
            raise # Re-raise the same error we caught.
          end
          response = e.response
        end
        if url.end_with?('/metadata')
          FHIR.logger.debug "GET - Request: #{response.request.to_json}, Response: [too large]"
        else
          FHIR.logger.debug "GET - Request: #{response.request.to_json}, Response: #{response.body.force_encoding('UTF-8')}"
        end
        response.request.args[:path] = response.request.args[:url].gsub(@base_service_url, '')
        headers = response.headers.each_with_object({}) { |(k, v), h| h[k.to_s.tr('_', '-')] = v.to_s; h }
        res = {
          code: response.code,
          headers: scrubbed_response_headers(headers),
          body: response.body
        }

        @reply = FHIR::ClientReply.new(response.request.args, res, self)
      end
    end

    def post(path, resource, headers)
      url = URI(build_url(path)).to_s
      FHIR.logger.info "POSTING: #{url}"
      headers = clean_headers(headers)
      payload = request_payload(resource, headers) if resource
      if @use_oauth2_auth
        # @client.refresh!
        begin
          response = @client.post(url, headers: headers, body: payload)
        rescue => e
          unless e.response
            # Re-raise the client error if there's no response. Otherwise, logging
            # and other things break below!
            FHIR.logger.error "POST - Request: #{url} failed! No response from server: #{e}"
            raise # Re-raise the same error we caught.
          end
          response = e.response if e.response
        end
        req = {
          method: :post,
          url: url,
          path: url.gsub(@base_service_url, ''),
          headers: headers,
          payload: payload
        }
        res = {
          code: response.status.to_s,
          headers: response.headers,
          body: response.body
        }
        FHIR.logger.debug "POST - Request: #{req}, Response: #{response.body.force_encoding('UTF-8')}"
        @reply = FHIR::ClientReply.new(req, res, self)
      else
        headers.merge!(@security_headers) if @use_basic_auth
        @client.post(url, payload, headers) do |resp, request, result|
          FHIR.logger.debug "POST - Request: #{request.to_json}\nResponse:\nResponse Headers: #{scrubbed_response_headers(result.each_key {})} \nResponse Body: #{resp.force_encoding('UTF-8')}"
          request.args[:path] = url.gsub(@base_service_url, '')
          res = {
            code: result.code,
            headers: scrubbed_response_headers(result.each_key {}),
            body: resp
          }
          @reply = FHIR::ClientReply.new(request.args, res, self)
        end
      end
    end

    def put(path, resource, headers)
      url = URI(build_url(path)).to_s
      FHIR.logger.info "PUTTING: #{url}"
      headers = clean_headers(headers)
      payload = request_payload(resource, headers) if resource
      if @use_oauth2_auth
        # @client.refresh!
        begin
          response = @client.put(url, headers: headers, body: payload)
        rescue => e
          unless e.response
            # Re-raise the client error if there's no response. Otherwise, logging
            # and other things break below!
            FHIR.logger.error "PUT - Request: #{url} failed! No response from server: #{e}"
            raise # Re-raise the same error we caught.
          end
          response = e.response if e.response
        end
        req = {
          method: :put,
          url: url,
          path: url.gsub(@base_service_url, ''),
          headers: headers,
          payload: payload
        }
        res = {
          code: response.status.to_s,
          headers: response.headers,
          body: response.body
        }
        FHIR.logger.debug "PUT - Request: #{req}, Response: #{response.body.force_encoding('UTF-8')}"
        @reply = FHIR::ClientReply.new(req, res, self)
      else
        headers.merge!(@security_headers) if @use_basic_auth
        @client.put(url, payload, headers) do |resp, request, result|
          FHIR.logger.debug "PUT - Request: #{request.to_json}, Response: #{resp.force_encoding('UTF-8')}"
          request.args[:path] = url.gsub(@base_service_url, '')
          res = {
            code: result.code,
            headers: scrubbed_response_headers(result.each_key {}),
            body: resp
          }
          @reply = FHIR::ClientReply.new(request.args, res, self)
        end
      end
    end

    def patch(path, patchset, headers)
      url = URI(build_url(path)).to_s
      FHIR.logger.info "PATCHING: #{url}"
      headers = clean_headers(headers)
      payload = request_patch_payload(patchset, headers['format'])
      if @use_oauth2_auth
        # @client.refresh!
        begin
          response = @client.patch(url, headers: headers, body: payload)
        rescue => e
          unless e.response
            # Re-raise the client error if there's no response. Otherwise, logging
            # and other things break below!
            FHIR.logger.error "PATCH - Request: #{url} failed! No response from server: #{e}"
            raise # Re-raise the same error we caught.
          end
          response = e.response if e.response
        end
        req = {
          method: :patch,
          url: url,
          path: url.gsub(@base_service_url, ''),
          headers: headers,
          payload: payload
        }
        res = {
          code: response.status.to_s,
          headers: response.headers,
          body: response.body
        }
        FHIR.logger.debug "PATCH - Request: #{req}, Response: #{response.body.force_encoding('UTF-8')}"
        @reply = FHIR::ClientReply.new(req, res, self)
      else
        headers.merge!(@security_headers) if @use_basic_auth
        begin
          @client.patch(url, payload, headers) do |resp, request, result|
            FHIR.logger.debug "PATCH - Request: #{request.to_json}, Response: #{resp.force_encoding('UTF-8')}"
            request.args[:path] = url.gsub(@base_service_url, '')
            res = {
              code: result.code,
              headers: scrubbed_response_headers(result.each_key {}),
              body: resp
            }
            @reply = FHIR::ClientReply.new(request.args, res, self)
          end
        rescue => e
          unless e.response
            # Re-raise the client error if there's no response. Otherwise, logging
            # and other things break below!
            FHIR.logger.error "PATCH - Request: #{url} failed! No response from server: #{e}"
            raise # Re-raise the same error we caught.
          end
          req = {
            method: :patch,
            url: url,
            path: url.gsub(@base_service_url, ''),
            headers: headers,
            payload: payload
          }
          res = {
            body: e.message
          }
          FHIR.logger.debug "PATCH - Request: #{req}, Response: #{response.body.force_encoding('UTF-8')}"
          FHIR.logger.error "PATCH Error: #{e.message}"
          @reply = FHIR::ClientReply.new(req, res, self)
        end
      end
    end

    def delete(path, headers)
      url = URI(build_url(path)).to_s
      FHIR.logger.info "DELETING: #{url}"
      headers = clean_headers(headers)
      if @use_oauth2_auth
        # @client.refresh!
        begin
          response = @client.delete(url, headers: headers)
        rescue => e
          unless e.response
            # Re-raise the client error if there's no response. Otherwise, logging
            # and other things break below!
            FHIR.logger.error "DELETE - Request: #{url} failed! No response from server: #{e}"
            raise # Re-raise the same error we caught.
          end
          response = e.response if e.response
        end
        req = {
          method: :delete,
          url: url,
          path: url.gsub(@base_service_url, ''),
          headers: headers,
          payload: nil
        }
        res = {
          code: response.status.to_s,
          headers: response.headers,
          body: response.body
        }
        FHIR.logger.debug "DELETE - Request: #{req}, Response: #{response.body.force_encoding('UTF-8')}"
        @reply = FHIR::ClientReply.new(req, res, self)
      else
        headers.merge!(@security_headers) if @use_basic_auth
        @client.delete(url, headers) do |resp, request, result|
          FHIR.logger.debug "DELETE - Request: #{request.to_json}, Response: #{resp.force_encoding('UTF-8')}"
          request.args[:path] = url.gsub(@base_service_url, '')
          res = {
            code: result.code,
            headers: scrubbed_response_headers(result.each_key {}),
            body: resp
          }
          @reply = FHIR::ClientReply.new(request.args, res, self)
        end
      end
    end

    def head(path, headers)
      headers.merge!(@security_headers) unless @security_headers.blank?
      url = URI(build_url(path)).to_s
      FHIR.logger.info "HEADING: #{url}"
      RestClient.head(url, headers) do |response, request, result|
        FHIR.logger.debug "HEAD - Request: #{request.to_json}, Response: #{response.force_encoding('UTF-8')}"
        request.args[:path] = url.gsub(@base_service_url, '')
        res = {
          code: result.code,
          headers: scrubbed_response_headers(result.each_key {}),
          body: response
        }
        @reply = FHIR::ClientReply.new(request.args, res, self)
      end
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
