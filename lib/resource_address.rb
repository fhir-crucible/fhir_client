module FHIR
  class ResourceAddress

    DEFAULTS = {
      id: nil,
      resource: nil,
      format: 'application/xml+fhir',
    }

    DEFAULT_CHARSET = 'UTF-8'

    def fhir_headers(options, use_format_param=false)
      options = DEFAULTS.merge(options)

      params = {}
      # params[:_format] = options[:format] if options[:format]

      fhir_headers = {
        'User-Agent' => 'Ruby FHIR Client for FHIR',
        'Content-Type' => 'charset=' + DEFAULT_CHARSET,
        'Accept-Charset' => DEFAULT_CHARSET
      }

      if(options[:category])
        # options[:category] should be an Array of FHIR::Tag objects
        tags = {
          'Category' => options[:category].collect { |h| h.to_header }.join(',')
        }
        fhir_headers.merge!(tags)
        options.delete(:category)
      end

      unless use_format_param
        format = options[:format] || FHIR::Formats::ResourceFormat::RESOURCE_XML
        header = {
          'Accept' => format,
          'Content-Type' => format + ';charset=' + DEFAULT_CHARSET
        }
        fhir_headers.merge!(header)
      end

      fhir_headers.merge!(options) unless options.blank?
      fhir_headers[:operation] = options[:operation][:name] if options[:operation] && options[:operation][:name]
      fhir_headers.merge!(params) unless params.blank?
      fhir_headers
    end

    def resource_url(options, use_format_param=false)
      options = DEFAULTS.merge(options)

      params = {}
      url = ""
      # handle requests for resources by class or string; useful for testing nonexistent resource types
      url += "/#{ options[:resource].try(:name).try(:demodulize) || options[:resource].split("::").last }" if options[:resource]
      url += "/#{options[:id]}" if options[:id]
      url += "/$validate" if options[:validate]

      if(options[:operation])
        opr = options[:operation]
        p = opr[:parameters]
        p = p.each{|k,v|p[k]=v[:value]} if p
        params.merge!(p) if p && opr[:method]=='GET'

        if (opr[:name] == :fetch_patient_record)
          url += "/$everything"
        elsif (opr[:name] == :value_set_expansion)
          url += "/$expand"
        elsif (opr  && opr[:name]== :value_set_based_validation)
          url += "/$validate-code"
        elsif (opr  && opr[:name]== :value_set_code_lookup)
          url += "/$lookup"
        end
      end

      if (options[:history])
        history = options[:history]
        url += "/_history/#{history[:id]}"
        params[:_count] = history[:count] if history[:count]
        params[:_since] = history[:since].iso8601 if history[:since]
      end

      if(options[:search])
        search_options = options[:search]
        url += '/_search' if search_options[:flag]
        url += "/#{search_options[:compartment]}" if search_options[:compartment]

        if search_options[:parameters]
          search_options[:parameters].each do |key,value|
            params[key.to_sym] = value
          end
        end
      end

      if(options[:summary])
        params[:_summary] = options[:summary]
      end

      if use_format_param && options[:format]
        params[:_format] = options[:format]
      end

      uri = Addressable::URI.parse(url)
      uri.query_values = params
      uri.normalize.to_str
    end

    # Get the resource ID out of the URL (e.g. Bundle.entry.response.location)
    def self.pull_out_id(resourceType,url)
      id = nil
      if !resourceType.nil? && !url.nil?
        token = "#{resourceType}/"
        start = url.index(token) + token.length
        t = url[start..-1]
        stop = t.index("/")-1
        stop = -1 if stop.nil?
        id = t[0..stop]
      end
      id
    end

    def self.append_forward_slash_to_path(path)
      path += '/' unless path.last == '/'
      path
    end

  end
end
