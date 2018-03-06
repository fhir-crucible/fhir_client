module FHIR
  module Sections
    module BulkData

      BULK_DATA_FORMAT = 'application/fhir+ndjson'
      BULK_DATA_POLLING_RATE = 2 # seconds

      # this uses the response body
      # parameters can be 'start' (an instant)
      # and '_type' (a comma-seperated list of Resources: Patient,Observation)
      def bulk_data(start: nil, type: nil, &handler_block)
        # parameters = {
        #   'start': instant,
        #   '_type': [ Patient, Observation ]
        # }
        parameters = {}
        if start
          puts "'start' parameter is not a valid datetime: #{start}" unless FHIR.primitive?(datatype: 'datetime', value: start)
        end
        parameters['start'] = { value: start} if start
        if type
          list = type.split(',')
          list = list.keep_if{ |type| FHIR::RESOURCES.include?(type) || FHIR::DSTU2::RESOURCES.include?(type) }
          list = list.join(',')
          puts "'_type': #{list}"
        end
        parameters['_type'] = { value: type} if type

        options = { 
          resource: versioned_resource_class('Patient'), 
          'Prefer': 'respond-async',
          'output-format': BULK_DATA_FORMAT,
          'Accept': BULK_DATA_FORMAT,
          format: BULK_DATA_FORMAT, 
          operation: { name: :fetch_patient_record, method: 'GET' }
        }
        options[:operation][:parameters] = parameters unless parameters.empty?

        url = resource_url(options)
        headers = fhir_headers(options)

        binding.pry

        reply = get url, headers
        if reply.code == 202
          content_location = reply.response[:headers]['content-location']
          puts "Bulk Data Location: #{content_location}"
        else
          # Error?
          binding.pry
        end

        while reply.code == 202
          reply = get content_location, fhir_headers(options) #{}
          progress = reply.response[:headers]['x-progress']
          puts "Progress: #{progress}"
          sleep(BULK_DATA_POLLING_RATE)
        end

        if reply.code == 200
          results = JSON.parse(reply.body)
          results['output'].each do |item|
            link = item['url']
            block = proc { |response|
              ndjson = ''
              response.read_body do |chunk|
                # each chunk portion of a newline delimited
                # json stream. the beginning and ending of the
                # chunk may not be complete json (i.e. it can
                # be broken in half)
                ndjson += chunk
                ndjson.split("\n").each do |json|
                  begin
                    # this should be a complete json document.
                    # if not, we jump to the rescue clause.
                    resource = nil
                    if @fhir_version == :stu3
                      resource = FHIR::Json.from_json(json)
                    elsif @fhir_version == :dstu2
                      resource = FHIR::DSTU2::Json.from_json(json)
                    end
                    instance_exec resource, &handler_block
                    # yield w/ resource
                    # instance_eval block w/resource
                  rescue
                    # incomplete chunk of json,
                    # reset the ndjson to start here.
                    ndjson = json
                  end
                end
              end
            }
            RestClient::Request.execute(method: :get, url: link, block_response: block)
          end
        else
          # Error?
          binding.pry
        end

      end

      # this uses the response `link` header
      def bulk_data_old(&handler_block)
        options = { 
          resource: versioned_resource_class('Patient'), 
          'Prefer': 'respond-async',
          'Accept': BULK_DATA_FORMAT,
          format: BULK_DATA_FORMAT, 
          operation: { name: :fetch_patient_record }
        }

        reply = get resource_url(options), fhir_headers(options)
        if reply.code == 202
          content_location = reply.response[:headers]['content-location']
          puts "Bulk Data Location: #{content_location}"
        else
          # Error?
          binding.pry
        end

        while reply.code == 202
          reply = get content_location, fhir_headers(options) #{}
          progress = reply.response[:headers]['x-progress']
          puts "Progress: #{progress}"
          sleep(BULK_DATA_POLLING_RATE)
        end

        if reply.code == 200
          links = reply.response[:headers]['link'].split(',')
          links.map!{ |link| link[1..-2] }
          
          links.each do |link|
            block = proc { |response|
              ndjson = ''
              response.read_body do |chunk|
                # each chunk portion of a newline delimited
                # json stream. the beginning and ending of the
                # chunk may not be complete json (i.e. it can
                # be broken in half)
                ndjson += chunk
                ndjson.split("\n").each do |json|
                  begin
                    # this should be a complete json document.
                    # if not, we jump to the rescue clause.
                    resource = nil
                    if @fhir_version == :stu3
                      resource = FHIR::Json.from_json(json)
                    elsif @fhir_version == :dstu2
                      resource = FHIR::DSTU2::Json.from_json(json)
                    end
                    instance_exec resource, &handler_block
                    # yield w/ resource
                    # instance_eval block w/resource
                  rescue
                    # incomplete chunk of json,
                    # reset the ndjson to start here.
                    ndjson = json
                  end
                end
              end
            }
            RestClient::Request.execute(method: :get, url: link, block_response: block)
          end
        else
          # Error?
          binding.pry
        end

      end

    end
  end
end