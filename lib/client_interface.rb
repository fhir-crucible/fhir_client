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
    @baseServiceUrl = baseServiceUrl
    @use_format_param = false
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
    options = { format: format }
    reply = get 'metadata', fhir_headers(options)
    parse_reply(FHIR::Conformance, format, reply.body)
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

  def fhir_headers(options={})
    FHIR::ResourceAddress.new.fhir_headers(options, @use_format_param)
  end

  def parse_reply(klass, format, response)
    FHIR::ResourceAddress.parse_resource(response, format, klass) if [200, 201].include? response.code
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
        @baseServiceUrl
      else
        FHIR::ResourceAddress.append_forward_slash_to_path(@baseServiceUrl)
      end
    end

    def strip_base(path)
      path.gsub(@baseServiceUrl, '')
    end


    def get(path, headers)
      puts "GETTING: #{base_path(path)}#{path}"
      RestClient.get(URI(URI.escape("#{base_path(path)}#{path}")).to_s, headers){ |response, request, result| FHIR::ClientReply.new(request, response) }
    end

    def post(path, resource, headers)
      puts "POSTING: #{base_path(path)}#{path}"
      RestClient.post(URI(URI.escape("#{base_path(path)}#{path}")).to_s, resource.to_xml, headers) { |response, request, result| FHIR::ClientReply.new(request, response) }
    end

    def put(path, resource, headers)
      puts "PUTTING: #{base_path(path)}#{path}"
      RestClient.put(URI(URI.escape("#{base_path(path)}#{path}")).to_s, resource.to_xml, headers) { |response, request, result| FHIR::ClientReply.new(request, response) }
    end

    def delete(path, headers)
      puts "DELETING: #{base_path(path)}#{path}"
      RestClient.delete(URI(URI.escape("#{base_path(path)}#{path}")).to_s, headers) { |response, request, result| FHIR::ClientReply.new(request, response) }
    end

  end

end
