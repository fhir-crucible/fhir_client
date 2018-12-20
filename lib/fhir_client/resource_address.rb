module FHIR
  class ResourceAddress
    DEFAULTS = {
      id: nil,
      resource: nil,
      format: 'application/fhir+xml'
    }.freeze

    DEFAULT_CHARSET = 'utf-8'.freeze
    DEFAULT_CONTENT_TYPE = 'application/fhir+xml' # time to default to json?

    #
    # Normalize submitted header key value pairs
    #
    # 'content-type', 'Content-Type', and :content_type would all represent the content-type header
    #
    # Assumes symbols like :content_type to be "content-type"
    # if for some odd reason the Header string representation contains underscores it would need to be specified
    # as a string (i.e. options {"Underscore_Header" => 'why not hyphens'})
    # Note that servers like apache or nginx consider that invalid anyways and drop them
    # http://httpd.apache.org/docs/trunk/new_features_2_4.html
    # http://nginx.org/en/docs/http/ngx_http_core_module.html#underscores_in_headers
    def self.normalize_headers(to_be_normalized, to_symbol = true, capitalized = false)
      to_be_normalized.inject({}) do |result, (key, value)|
        key = key.to_s.downcase.split(/-|_/)
        key.map!(&:capitalize) if capitalized
        key = to_symbol ? key.join('_').to_sym : key.join('-')
        result[key] = value.to_s
        result
      end
    end

    def self.convert_symbol_headers headers
      headers.inject({}) do |result, (key, value)|
        if key.is_a? Symbol
          key = key.to_s.split(/_/).map(&:capitalize).join('-')
        end
        result[key] = value.to_s
        result
      end
    end

    # Returns normalized HTTP Headers
    # header key value pairs can be supplied with keys specified as symbols or strings
    # keys will be normalized to symbols.
    # e.g. the keys :accept, "accept", and "Accept" all represent the Accept HTTP Header
    # @param [Hash] options key value pairs for the http headerx
    # @return [Hash] The normalized FHIR Headers
    def self.fhir_headers(headers = nil, additional_headers = {}, format = DEFAULT_CONTENT_TYPE, use_accept_header = true, use_accept_charset = true)
      # normalizes header names to be case-insensitive
      # See relevant HTTP RFCs:
      # https://tools.ietf.org/html/rfc2616#section-4.2
      # https://tools.ietf.org/html/rfc7230#section-3.2
      #
      # https://tools.ietf.org/html/rfc7231#section-5.3.2
      # optional white space before and
      # https://tools.ietf.org/html/rfc2616#section-3.4
      # utf-8 is case insensitive
      #
      headers ||= {}
      additional_headers ||= {}

      fhir_headers = {user_agent: 'Ruby FHIR Client'}

      fhir_headers[:accept_charset] =  DEFAULT_CHARSET if use_accept_charset

      # https://www.hl7.org/fhir/DSTU2/http.html#mime-type
      # could add option for ;charset=#{DEFAULT_CHARSET} in accept header
      fhir_headers[:accept] = "#{format}" if use_accept_header

      # maybe in a future update normalize everything to symbols
      # Headers should be case insensitive anyways...
      #headers = normalize_headers(headers) unless headers.empty?
      #
      fhir_headers = convert_symbol_headers(fhir_headers)
      headers = convert_symbol_headers(headers)

      # supplied headers will always be used, e.g. if @use_accept_header is false
      # ,but an accept header is explicitly supplied then it will be used (or override the existing)
      fhir_headers.merge!(headers) unless headers.empty?
      fhir_headers.merge!(additional_headers)
      fhir_headers
    end

    def self.resource_url(options, use_format_param = false)
      options = DEFAULTS.merge(options)

      params = {}
      url = ''
      # handle requests for resources by class or string; useful for testing nonexistent resource types
      url += "/#{options[:resource].try(:name).try(:demodulize) || options[:resource].split('::').last}" if options[:resource]
      url += "/#{options[:id]}" if options[:id]
      url += '/$validate' if options[:validate]
      url += '/$match' if options[:match]

      if options[:operation]
        opr = options[:operation]
        p = opr[:parameters]
        p = p.each { |k, v| p[k] = v[:value] } if p
        params.merge!(p) if p && opr[:method] == 'GET'

        if opr[:name] == :fetch_patient_record
          url += '/$everything'
        elsif opr[:name] == :value_set_expansion
          url += '/$expand'
        elsif opr  && opr[:name] == :value_set_based_validation
          url += '/$validate-code'
        elsif opr  && opr[:name] == :code_system_lookup
          url += '/$lookup'
        elsif opr  && opr[:name] == :concept_map_translate
          url += '/$translate'
        elsif opr  && opr[:name] == :closure_table_maintenance
          url += '/$closure'
        end
      end

      if options[:history]
        history = options[:history]
        url += '/_history'
        url += "/#{history[:id]}" if history.key?(:id)
        params[:_count] = history[:count] if history[:count]
        params[:_since] = history[:since].iso8601 if history[:since]
      end

      if options[:search]
        search_options = options[:search]
        url += '/_search' if search_options[:flag]
        url += "/#{search_options[:compartment]}" if search_options[:compartment]

        if search_options[:parameters]
          search_options[:parameters].each do |key, value|
            params[key.to_sym] = value
          end
        end
      end

      # options[:params] is simply appended at the end of a url and is used by testscripts
      url += options[:params] if options[:params]

      params[:_summary] = options[:summary] if options[:summary]

      if use_format_param && options[:format]
        params[:_format] = options[:format]
      end

      uri = Addressable::URI.parse(url)
      # params passed in options takes precidence over params calculated in this method
      # for use by testscript primarily
      uri.query_values = params unless options[:params] && options[:params].include?('?')
      uri.normalize.to_str
    end

    # Get the resource ID out of the URL (e.g. Bundle.entry.response.location)
    def self.pull_out_id(resource_type, url)
      id = nil
      if !resource_type.nil? && !url.nil?
        token = "#{resource_type}/"
        if url.index(token)
          start = url.index(token) + token.length
          t = url[start..-1]
          stop = (t.index('/') || 0) - 1
          stop = -1 if stop.nil?
          id = t[0..stop]
        else
          id = nil
        end
      end
      id
    end

    def self.append_forward_slash_to_path(path)
      path += '/' unless path.last == '/'
      path
    end
  end
end
