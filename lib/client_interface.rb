module FHIR

  class Client

    attr_accessor :reply
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
  def conformanceStatement(format=FHIR::ResourceAddress::RESOURCE_XML)
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
    FHIR::ResourceAddress.new.resource_url(options)
  end

  def fhir_headers(options)
    FHIR::ResourceAddress.new.fhir_headers(options)
  end

  def parse_reply(klass, format, response)
    FHIR::ResourceAddress.parse_resource(response, format, klass)
  end

  #
  # Read the current state of a resource.
  # 
  # @param resource
  # @param id
  # @return
  #

  def read(klass, id, format=FHIR::ResourceAddress::RESOURCE_XML)
    options = { resource: klass, id: id, format: format }
    reply = get resource_url(options), fhir_headers(options)
    reply.resource = parse_reply(klass, format, reply.body)
    reply.resource_class = klass
    reply
  end

  #
  # Read a resource bundle (an XML ATOM feed)
  #
  def read_feed(klass, format=FHIR::ResourceAddress::FEED_XML)
    options = { resource: klass, format: format }
    reply = get resource_url(options), fhir_headers(options)
    reply.resource = parse_reply(klass, format, reply.body)
    reply.resource_class = klass
    reply
  end

  #
  # Read the state of a specific version of the resource
  # 
  # @param resource
  # @param id
  # @param versionid
  # @return
  #
  def vread(klass, id, version_id, format=FHIR::ResourceAddress::RESOURCE_XML)
    options = { resource: klass, id: id, format: format, history: {id: version_id} }
    reply = get resource_url(options), fhir_headers(options)
    reply.resource = parse_reply(klass, format, reply.body)
    reply.resource_class = klass
    reply
  end

  def raw_read(options)
    reply = get resource_url(options), fhir_headers(options)
    reply.body
  end

  def raw_read_url(url)
    reply = get url, fhir_headers({})
    reply.body
  end

  
  #
  # Update an existing resource by its id or create it if it is a new resource, not present on the server
  # 
  # @param resourceClass
  # @param resource
  # @param id
  # @return
  #
  # public <T extends Resource> AtomEntry<T> update(Class<T> resourceClass, T resource, String id);
  def update(resource, id, format=FHIR::ResourceAddress::RESOURCE_XML)
    options = { resource: resource.class, id: id, format: format }
    reply = put resource_url(options), resource, fhir_headers(options)
    # reply.resource = resource.class.from_xml(reply.body)
    reply.resource = resource
    reply.resource_class = resource.class
    reply
  end
  #
  # Update an existing resource by its id or create it if it is a new resource, not present on the server
  # 
  # @param resourceClass
  # @param resource
  # @param id
  # @return
  #
  # public <T extends Resource> AtomEntry<T> update(Class<T> resourceClass, T resource, String id, List<AtomCategory> tags);
  
  #
  # Delete the resource with the given ID.
  # 
  # @param resourceClass
  # @param id
  # @return
  #
  def destroy(klass, id)
    options = { resource: klass, id: id, format: nil }
    reply = delete resource_url(options), fhir_headers(options)
    reply.resource_class = klass
    reply
  end
  # public <T extends Resource> boolean delete(Class<T> resourceClass, String id); 

  #
  # Create a new resource with a server assigned id. Return the newly created
  # resource with the id the server assigned.
  # 
  # @param resourceClass
  # @param resource
  # @return
  #
  def create(resource)
    options = { resource: resource.class, format: nil }
    reply = post resource_url(options), resource, fhir_headers(options)
    #reply.resource = resource.class.from_xml(reply.body)
    reply.resource = resource
    reply.resource_class = resource.class   
    reply
  end
  
  #
  # Create a new resource with a server assigned id. Return the newly created
  # resource with the id the server assigned. Associates tags with newly created resource.
  # 
  # @param resourceClass
  # @param resource
  # @return
  #
  # public <T extends Resource> AtomEntry<OperationOutcome> create(Class<T> resourceClass, T resource, List<AtomCategory> tags);
  
  #
  # Retrieve the update history for a resource with given id since last update time. 
  # Last update may be null TODO - ensure this is the case.
  # 
  # @param lastUpdate
  # @param resourceClass
  # @param id
  # @return
  #
  # public <T extends Resource> AtomFeed history(Calendar lastUpdate, Class<T> resourceClass, String id);
  # public <T extends Resource> AtomFeed history(DateAndTime lastUpdate, Class<T> resourceClass, String id);
  
  def history(options)
    reply = get FHIR::ResourceAddress.new.resource_url(options), fhir_headers(options)
    reply.resource = parse_reply(options[:resource], FHIR::ResourceAddress::FEED_XML, reply.body)
    reply.resource_class = options[:resource]
    reply
  end

  #
  # Retrieve the entire update history for a resource with the given id.
  # Last update may be null TODO - ensure this is the case.
  # 
  # @param resourceClass
  # @param id
  # @param lastUpdate
  # @return
  #
  def resource_instance_history_as_of(klass, id, lastUpdate)
    history(resource: klass, id: id, history:{since: lastUpdate})
  end

  def resource_instance_history(klass, id)
    history(resource: klass, id: id, history:{})
  end

  def resource_history(klass)
    history(resource: klass, history:{})
  end
  
  #
  # Retrieve the update history for all resource types since the start of server records.
  # 
  def all_history
    history(history:{})
  end

  #
  # Retrieve the update history for all resource types since a specific last update date/time.
  # 
  # Note: 
  # @param lastUpdate
  # @return
  #
  def all_history_as_of(lastUpdate)
    history(history:{since: lastUpdate})
  end

  #
  # Validate resource payload.
  # 
  # @param resourceClass
  # @param resource
  # @param id
  # @return
  #
  # public <T extends Resource> AtomEntry<OperationOutcome> validate(Class<T> resourceClass, T resource, String id);
  
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
  # Get a list of all tags on server 
  # 
  # GET [base]/_tags
  #
  # public List<AtomCategory> getAllTags();
  
  #
  # Get a list of all tags used for the nominated resource type 
  # 
  # GET [base]/[type]/_tags
  #
  # public <T extends Resource> List<AtomCategory> getAllTagsForResourceType(Class<T> resourceClass);
  
  #
  # Get a list of all tags affixed to the nominated resource. This duplicates the HTTP header entries 
  # 
  # GET [base]/[type]/[id]/_tags
  #
  # public <T extends Resource> List<AtomCategory> getTagsForResource(Class<T> resource, String id);
  
  #
  # Get a list of all tags affixed to the nominated version of the resource. This duplicates the HTTP header entries
  # 
  # GET [base]/[type]/[id]/_history/[vid]/_tags
  #
  # public <T extends Resource> List<AtomCategory> getTagsForResourceVersion(Class<T> resource, String id, String versionId);
  
  #
  # Remove all tags in the provided list from the list of tags for the nominated resource
  # 
  # DELETE [base]/[type]/[id]/_tags
  #
  # //public <T extends Resource> boolean deleteTagsForResource(Class<T> resourceClass, String id);
  
  #
  # Remove tags in the provided list from the list of tags for the nominated version of the resource
  # 
  # DELETE [base]/[type]/[id]/_history/[vid]/_tags
  #
  # public <T extends Resource> List<AtomCategory> deleteTags(List<AtomCategory> tags, Class<T> resourceClass, String id, String version);
  
  #
  # Affix tags in the list to the nominated resource
  # 
  # POST [base]/[type]/[id]/_tags
  # @return
  #
  # public <T extends Resource> List<AtomCategory> createTags(List<AtomCategory> tags, Class<T> resourceClass, String id);
  
  #
  # Affix tags in the list to the nominated version of the resource
  # 
  # POST [base]/[type]/[id]/_history/[vid]/_tags
  # 
  # @return
  #
  # public <T extends Resource> List<AtomCategory> createTags(List<AtomCategory> tags, Class<T> resourceClass, String id, String version);

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

    def get(path, headers)
      puts "GETTING: #{base_path(path)}#{path}"
      RestClient.get(URI("#{base_path(path)}#{path}").to_s, headers){ |response, request, result| FHIR::ClientReply.new(request, response) }
    end

    def post(path, resource, headers)
      puts "POSTING: #{base_path(path)}#{path}"
      RestClient.post(URI("#{base_path(path)}#{path}").to_s, resource.to_xml, headers) { |response, request, result| FHIR::ClientReply.new(request, response) }
    end

    def put(path, resource, headers)
      puts "PUTTING: #{base_path(path)}#{path}"
      RestClient.put(URI("#{base_path(path)}#{path}").to_s, resource.to_xml, headers) { |response, request, result| FHIR::ClientReply.new(request, response) }
    end

    def delete(path, headers)
      puts "DELETING: #{base_path(path)}#{path}"
      RestClient.delete(URI("#{base_path(path)}#{path}").to_s, headers) { |response, request, result| FHIR::ClientReply.new(request, response) }
    end

  end

end