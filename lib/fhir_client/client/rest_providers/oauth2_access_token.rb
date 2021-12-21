module FHIR
  class Client
    class RestProviders
      class OAuth2
        class AccessToken
          def self.refresh_token_for(fhir_client, **params)
            return unless fhir_client.client.refresh_token

            if params[:force] || fhir_client.client.expired?
              FHIR.logger.debug "OAuth2 token refresh invoked"
              fhir_client.client = fhir_client.client.refresh!
            end
          end

          # All of the OAuth2 logic is common across all methods
          def self.request(action, fhir_client, url, **params)
            attempted_action ||= false
            action_name = action.to_s.upcase

            refresh_token_for fhir_client

            begin
              response = fhir_client.client.request action, url, **params.slice(:headers, :body)
              status   = response.status.to_s
              raise ::FHIR::Client::Error::HTTP_CODE[status] if ['401'].include? status
            rescue ::FHIR::Client::Error::HTTPUnauthorized
              unless attempted_action
                attempted_action = true
                refresh_token_for fhir_client, force: true
                retry
              end
            rescue => e
              if !e.respond_to?(:response) || e.response.nil?
                # Re-raise the client error if there's no response. Otherwise, logging
                # and other things break below!
                FHIR.logger.error "#{action_name} - Request: #{url} failed! No response from server: #{e}"
                raise # Re-raise the same error we caught.
              end
              response = e.response if e.response
            end

            req = {
              method: action,
              url: url,
              path: url.gsub(params[:base_service_url], ''),
              headers: params[:headers],
              payload: params[:body]
            }
            res = {
              code: response.status.to_s,
              headers: response.headers,
              body: response.body
            }
            
            if url.end_with?('/metadata')
              FHIR.logger.debug "#{action_name} - Request: #{req}, Response: [metadata, too large]"
            else
              FHIR.logger.debug "#{action_name} - Request: #{req}, Response: #{response.body.force_encoding('UTF-8')}"
            end

            FHIR::ClientReply.new(req, res, fhir_client)
          end
        end
      end
    end
  end
end
