module FHIR
  class Client
    class RestProviders
      class RestClient
        def self.scrubbed_response_headers(result)
          result.each_key do |k|
            v = result[k]
            result[k] = v[0] if v.is_a? Array
          end
        end

        def self.request(action, fhir_client, url, **params)
          params[:headers].merge! params[:credentials]
          send action, fhir_client, url, **params
        end

        def self.get(fhir_client, url, **params)
          begin
            response = fhir_client.client.get(url, params[:headers])
          rescue ::RestClient::SSLCertificateNotVerified => sslerr
            return handle_ssl_error(sslerr, fhir_client, url, **params)
          rescue => e
            response = handle_response_error(e)
          end

          response.request.args[:path] = response.request.args[:url].gsub(params[:base_service_url], '')
          headers = response.headers.each_with_object({}) { |(k, v), h| h[k.to_s.tr('_', '-')] = v.to_s; h }
          res = {
            code: response.code,
            headers: scrubbed_response_headers(headers),
            body: response.body
          }
          debug_line url, response.request.to_json, response.body

          FHIR::ClientReply.new(response.request.args, res, fhir_client)
        end

        def self.post(fhir_client, url, **params)
          fhir_client.client.post(url, params[:body], params[:headers]) do |resp, request, result|
            request.args[:path] = url.gsub(params[:base_service_url], '')
            res = {
              code: result.code,
              headers: scrubbed_response_headers(result.each_key {}),
              body: resp
            }
            debug_line url, request.to_json, [
              '',
              "Response Headers: #{res[:headers]}",
              "Response Body: #{res[:body]}"
            ].join('\n')

            FHIR::ClientReply.new(request.args, res, fhir_client)
          end

        end

        def self.put(fhir_client, url, **params)
          fhir_client.client.put(url, params[:body], params[:headers]) do |resp, request, result|
            request.args[:path] = url.gsub(params[:base_service_url], '')
            res = {
              code: result.code,
              headers: scrubbed_response_headers(result.each_key {}),
              body: resp
            }
            debug_line url, request.to_json, resp

            FHIR::ClientReply.new(request.args, res, fhir_client)
          end
        end

        def self.patch(fhir_client, url, **params)
          begin
            fhir_client.client.patch(url, params[:body], params[:headers]) do |resp, request, result|
              request.args[:path] = url.gsub(params[:base_service_url], '')
              res = {
                code: result.code,
                headers: scrubbed_response_headers(result.each_key {}),
                body: resp
              }
              debug_line url, request.to_json, resp
              FHIR::ClientReply.new(request.args, res, fhir_client)
            end
          rescue => e
            handle_response_error(e)

            req = {
              method: :patch,
              url: url,
              path: url.gsub(params[:base_service_url], ''),
              headers: headers,
              payload: payload
            }
            res = {
              body: e.message
            }

            debug_line url, req, response.body
            error_line e.message
            FHIR::ClientReply.new(req, res, fhir_client)
          end
        end

        def self.delete(fhir_client, url, **params)
          fhir_client.client.delete(url, params[:headers]) do |resp, request, result|
            request.args[:path] = url.gsub(params[:base_service_url], '')
            res = {
              code: result.code,
              headers: scrubbed_response_headers(result.each_key {}),
              body: resp
            }
            debug_line url, request.to_json, resp
            FHIR::ClientReply.new(request.args, res, fhir_client)
          end
        end

        def self.head(fhir_client, url, **params)
          fhir_client.client.head(url, params[:headers]) do |response, request, result|
            debug_line url, req, response
            request.args[:path] = url.gsub(params[:base_service_url], '')
            res = {
              code: result.code,
              headers: scrubbed_response_headers(result.each_key {}),
              body: response
            }
            FHIR::ClientReply.new(request.args, res, fhir_client)
          end
        end

        # Common debug line output
        def self.debug_line(url, request, response)
          action_name = caller_locations(1..1).first.label.upcase

          if url.end_with?('/metadata')
            FHIR.logger.debug "#{action_name} - Request: #{request}, Response: [metadata, too large]"
          else
            FHIR.logger.debug "#{action_name} - Request: #{request}, Response: #{response.force_encoding('UTF-8')}"
          end
        end

        def self.error_line(message)
          action_name = caller_locations(1..1).first.label.upcase
          FHIR.logger.debug "#{action_name} Error: #{message}"
        end

        def self.handle_ssl_error(sslerr, fhir_client, url, **params)
          req = {
            method: caller_locations(1..1).first.label.to_sym,
            url: url,
            path: url.gsub(params[:base_service_url], ''),
            headers: params[:headers],
            payload: params[:body]
          }
          res = {
            body: sslerr.message
          }
          FHIR::ClientReply.new(req, res, fhir_client)
        end

        def self.handle_response_error(e)
          action_name = caller_locations(1..1).first.label.upcase.split(' ').last

          if !e.respond_to?(:response) || e.response.nil?
            FHIR.logger.error "GET - Request: #{action_name} failed! No response from server: #{e}"
            raise
          end
          e.response
        end
      end
    end
  end
end
