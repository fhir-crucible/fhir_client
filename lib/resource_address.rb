module FHIR
  class ResourceAddress

    DEFAULTS = {
      id: nil,
      resource: nil,
      format: 'application/fhir+xml',
      history: nil
    }

    RESOURCE_XML = "application/fhir+xml"
    RESOURCE_JSON = "application/fhir+json"

    FEED_XML = "application/atom+xml"
    FEED_JSON = "application/fhir+json"

    DEFAULT_CHARSET = 'UTF-8'

    def fhir_headers(options)
      options = DEFAULTS.merge(options)

      params = {}
      if (options[:history])
        history = options[:history]
        # url += "/_history/#{history[:id]}"
        params[:_count] = history[:count] if history[:count]
        params[:_since] = history[:since] if history[:since]
      end
      # params[:_format] = options[:format] if options[:format]
      format = options[:format] || RESOURCE_XML

      fhir_headers = {
        'User-Agent' => 'Ruby FHIR Client for FHIR',
        'Accept' => format,
        'Content-Type' => format + ';charset=' + DEFAULT_CHARSET,
        'Accept-Charset' => DEFAULT_CHARSET
      }
      fhir_headers.merge(options) unless options.blank?
      fhir_headers.merge(params) unless params.blank?
      fhir_headers
    end

#   public static final String REGEX_ID_WITH_HISTORY = "(.*)(/)([a-zA-Z]*)(/)(\\d+)(/_history/)(\\d+)$";
  
#   public <T extends Resource> URI resolveSearchUri(Class<T> resourceClass, Map<String,String> parameters) {
#     return appendHttpParameters(baseServiceUri.resolve(nameForClass(resourceClass) +"/_search"), parameters);
#   }
  
#   public <T extends Resource> URI resolveOperationUri(Class<T> resourceClass, String opName) {
#     return baseServiceUri.resolve(nameForClass(resourceClass) +"/$"+opName);
#   }
  
#   public <T extends Resource> URI resolveValidateUri(Class<T> resourceClass, String id) {
#     return baseServiceUri.resolve(nameForClass(resourceClass) +"/_validate/"+id);
#   }
  
#   public <T extends Resource> URI resolveGetUriFromResourceClass(Class<T> resourceClass) {
#     return baseServiceUri.resolve(nameForClass(resourceClass));
#   }

    def resource_url(options)
      options = DEFAULTS.merge(options)

      params = {}
      url = ""
      url += "/#{options[:resource].name.demodulize}" if options[:resource]
      url += "/_validate" if options[:validate]
      url += "/#{options[:id]}" if options[:id]
      if (options[:history])
        history = options[:history]
        url += "/_history/#{history[:id]}"
        params[:_count] = history[:count] if history[:count]
        params[:_since] = history[:since] if history[:since]
      end
      params[:_format] = options[:format] if options[:format]

      # url += "?#{params.to_a.map {|x| x.join('=')}.join('&')}" unless params.empty?

      url
    end

    def self.append_forward_slash_to_path(path)
      path += '/' unless path.last == '/'
      path
    end

    def self.parse_resource(response, format, klass)
      if format == RESOURCE_XML
        klass.from_xml(response)
      elsif format == RESOURCE_JSON
        klass.from_fhir_json(response)
      elsif format == FEED_XML || format == FEED_JSON
        FHIR::Bundle.new(klass, response)
      end
    end
  
#   public URI resolveGetHistoryForAllResources(int count) {
#     if(count > 0) {
#       return appendHttpParameter(baseServiceUri.resolve("_history"), "_count", ""+count);
#     } else {
#       return baseServiceUri.resolve("_history");
#     }
# }
  
#   public <T extends Resource> URI resolveGetHistoryForResourceId(Class<T> resourceClass, String id, int count) {
#     return resolveGetHistoryUriForResourceId(resourceClass, id, null, count);
#   }
  
#   protected <T extends Resource> URI resolveGetHistoryUriForResourceId(Class<T> resourceClass, String id, Object since, int count) {
#     Map<String,String>  parameters = getHistoryParameters(since, count);
#     return appendHttpParameters(baseServiceUri.resolve(nameForClass(resourceClass) + "/" + id + "/_history"), parameters);
#   }
  
#   public <T extends Resource> URI resolveGetHistoryForResourceType(Class<T> resourceClass, int count) {
#     Map<String,String>  parameters = getHistoryParameters(null, count);
#     return appendHttpParameters(baseServiceUri.resolve(nameForClass(resourceClass) + "/_history"), parameters);
#   }
  
#   public <T extends Resource> URI resolveGetHistoryForResourceType(Class<T> resourceClass, Object since, int count) {
#     Map<String,String>  parameters = getHistoryParameters(since, count);
#     return appendHttpParameters(baseServiceUri.resolve(nameForClass(resourceClass) + "/_history"), parameters);
#   }
  
#   public URI resolveGetHistoryForAllResources(Calendar since, int count) {
#     Map<String,String>  parameters = getHistoryParameters(since, count);
#     return appendHttpParameters(baseServiceUri.resolve("_history"), parameters);
#   }
  
#   public URI resolveGetHistoryForAllResources(DateAndTime since, int count) {
#     Map<String,String>  parameters = getHistoryParameters(since, count);
#     return appendHttpParameters(baseServiceUri.resolve("_history"), parameters);
#   }
  
#   public Map<String,String> getHistoryParameters(Object since, int count) {
#     Map<String,String>  parameters = new HashMap<String,String>();
#     if (since != null) {
#       parameters.put("_since", since.toString());
#     }
#     if(count > 0) {
#       parameters.put("_count", ""+count);
#     }
#     return parameters;
#   }
  
#   public <T extends Resource> URI resolveGetHistoryForResourceId(Class<T> resourceClass, String id, Calendar since, int count) {
#     return resolveGetHistoryUriForResourceId(resourceClass, id, since, count);
#   }
  
#   public <T extends Resource> URI resolveGetHistoryForResourceId(Class<T> resourceClass, String id, DateAndTime since, int count) {
#     return resolveGetHistoryUriForResourceId(resourceClass, id, since, count);
#   }
  
#   public <T extends Resource> URI resolveGetHistoryForResourceType(Class<T> resourceClass, Calendar since, int count) {
#     return resolveGetHistoryForResourceType(resourceClass, getCalendarDateInIsoTimeFormat(since), count);
#   }
  
#   public <T extends Resource> URI resolveGetHistoryForResourceType(Class<T> resourceClass, DateAndTime since, int count) {
#     return resolveGetHistoryForResourceType(resourceClass, since.toString(), count);
#   }
  
#   public <T extends Resource> URI resolveGetAllTags() {
#     return baseServiceUri.resolve("_tags");
#   }
  
#   public <T extends Resource> URI resolveGetAllTagsForResourceType(Class<T> resourceClass) {
#     return baseServiceUri.resolve(nameForClass(resourceClass) + "/_tags");
#   }
  
#   public <T extends Resource> URI resolveGetTagsForResource(Class<T> resourceClass, String id) {
#     return baseServiceUri.resolve(nameForClass(resourceClass) + "/" + id + "/_tags");
#   }
  
#   public <T extends Resource> URI resolveGetTagsForResourceVersion(Class<T> resourceClass, String id, String version) {
#     return baseServiceUri.resolve(nameForClass(resourceClass) +"/"+id+"/_history/"+version + "/_tags");
#   }
  
#   public <T extends Resource> URI resolveDeleteTagsForResourceVersion(Class<T> resourceClass, String id, String version) {
#     return baseServiceUri.resolve(nameForClass(resourceClass) +"/"+id+"/_history/"+version + "/_tags/_delete");
#   }
  
#   public <T extends Resource> String nameForClass(Class<T> resourceClass) {
#     String res = resourceClass.getSimpleName();
#     if (res.equals("List_"))
#       return "List";
#     else
#       return res;
#   }
  
#   public URI resolveMetadataUri() {
#     return baseServiceUri.resolve("metadata");
#   }
  
#   /**
#    * For now, assume this type of location header structure.
#    * Generalize later: http://hl7connect.healthintersections.com.au/svc/fhir/318/_history/1
#    * 
#    * @param serviceBase
#    * @param locationHeader
#    */
#   public static ResourceAddress.ResourceVersionedIdentifier parseCreateLocation(String locationResponseHeader) {
#     Pattern pattern = Pattern.compile(REGEX_ID_WITH_HISTORY);
#     Matcher matcher = pattern.matcher(locationResponseHeader);
#     ResourceVersionedIdentifier parsedHeader = null;
#     if(matcher.matches()){
#       String serviceRoot = matcher.group(1);
#       String resourceType = matcher.group(3);
#       String id = matcher.group(5);
#       String version = matcher.group(7);
#       parsedHeader = new ResourceVersionedIdentifier(serviceRoot, resourceType, id, version);
#     }
#     return parsedHeader;
#   }
  
#   public static URI buildAbsoluteURI(String absoluteURI) {
    
#     if(StringUtils.isBlank(absoluteURI)) {
#       throw new EFhirClientException("Invalid URI", new URISyntaxException(absoluteURI, "URI/URL cannot be blank"));
#     } 
    
#     String endpoint = appendForwardSlashToPath(absoluteURI);

#     return buildEndpointUriFromString(endpoint);
#   }
  
#   public static String appendForwardSlashToPath(String path) {
#     if(path.lastIndexOf('/') != path.length() - 1) {
#       path += "/";
#     }
#     return path;
#   }
  
#   public static URI buildEndpointUriFromString(String endpointPath) {
#     URI uri = null; 
#     try {
#       URIBuilder uriBuilder = new URIBuilder(endpointPath);
#       uri = uriBuilder.build();
#       String scheme = uri.getScheme();
#       String host = uri.getHost();
#       if(!scheme.equalsIgnoreCase("http") && !scheme.equalsIgnoreCase("https")) {
#         throw new EFhirClientException("Scheme must be 'http' or 'https': " + uri);
#       }
#       if(StringUtils.isBlank(host)) {
#         throw new EFhirClientException("host cannot be blank: " + uri);
#       }
#     } catch(URISyntaxException e) {
#       throw new EFhirClientException("Invalid URI", e);
#     }
#     return uri;
#   }
  
#   public static URI appendQueryStringToUri(URI uri, String parameterName, String parameterValue) {
#     URI modifiedUri = null;
#     try {
#       URIBuilder uriBuilder = new URIBuilder(uri);
#       uriBuilder.setQuery(parameterName + "=" + parameterValue);
#       modifiedUri = uriBuilder.build();
#     } catch(Exception e) {
#       throw new EFhirClientException("Unable to append query parameter '" + parameterName + "=" + parameterValue + " to URI " + uri, e);
#     }
#     return modifiedUri;
#   }
  
#   public static String buildRelativePathFromResourceType(ResourceType resourceType) {
#     //return resourceType.toString().toLowerCase()+"/";
#     return resourceType.toString() + "/";
#   }
  
#   public static String buildRelativePathFromResourceType(ResourceType resourceType, String id) {
#     return buildRelativePathFromResourceType(resourceType)+ "@" + id;
#   }
  
#   public static String buildRelativePathFromResource(Resource resource) {
#     return buildRelativePathFromResourceType(resource.getResourceType());
#   }
  
#   public static String buildRelativePathFromResource(Resource resource, String id) {
#     return buildRelativePathFromResourceType(resource.getResourceType(), id);
#   }
  
#   public static class ResourceVersionedIdentifier {
    
#     private String serviceRoot;
#     private String resourceType;
#     private String id;
#     private String version;
#     private URI resourceLocation;
    
#     public ResourceVersionedIdentifier(String serviceRoot, String resourceType, String id, String version, URI resourceLocation) {
#       this.serviceRoot = serviceRoot;
#       this.resourceType = resourceType;
#       this.id = id;
#       this.version = version;
#       this.resourceLocation = resourceLocation;
#     }
    
#     public ResourceVersionedIdentifier(String resourceType, String id, String version, URI resourceLocation) {
#       this(null, resourceType, id, version, resourceLocation);
#     }
    
#     public ResourceVersionedIdentifier(String serviceRoot, String resourceType, String id, String version) {
#       this(serviceRoot, resourceType, id, version, null);
#     }
    
#     public ResourceVersionedIdentifier(String resourceType, String id, String version) {
#       this(null, resourceType, id, version, null);
#     }
    
#     public ResourceVersionedIdentifier(String resourceType, String id) {
#       this.id = id;
#     }
    
#     public String getId() {
#       return this.id;
#     }
    
#     protected void setId(String id) {
#       this.id = id;
#     }
    
#     public String getVersionId() {
#       return this.version;
#     }
    
#     protected void setVersionId(String version) {
#       this.version = version;
#     }
    
#     public String getResourceType() {
#       return resourceType;
#     }

#     public void setResourceType(String resourceType) {
#       this.resourceType = resourceType;
#     }
    
#     public String getServiceRoot() {
#       return serviceRoot;
#     }

#     public void setServiceRoot(String serviceRoot) {
#       this.serviceRoot = serviceRoot;
#     }
    
#     public String getResourcePath() {
#       return this.serviceRoot + "/" + this.resourceType + "/" + this.id;
#     }

#     public String getVersion() {
#       return version;
#     }

#     public void setVersion(String version) {
#       this.version = version;
#     }

#     public URI getResourceLocation() {
#       return this.resourceLocation;
#     }
    
#     public void setResourceLocation(URI resourceLocation) {
#       this.resourceLocation = resourceLocation;
#     }
#   }
  
#   public static String getCalendarDateInIsoTimeFormat(Calendar calendar) {
#     SimpleDateFormat format = new SimpleDateFormat("YYYY-MM-dd'T'hh:mm:ss");//TODO Move out
#     format.setTimeZone(TimeZone.getTimeZone("GMT"));
#       return format.format(calendar.getTime());
#   }
  
#   public static URI appendHttpParameter(URI basePath, String httpParameterName, String httpParameterValue) {
#     Map<String, String> parameters = new HashMap<String, String>();
#     parameters.put(httpParameterName, httpParameterValue);
#     return appendHttpParameters(basePath, parameters);
#   }
  
#   public static URI appendHttpParameters(URI basePath, Map<String,String> parameters) {
#         try {
#           Set<String> httpParameterNames = parameters.keySet();
#           String query = basePath.getQuery();
          
#           for(String httpParameterName : httpParameterNames) {
#             if(query != null) {
#               query += "&";
#             } else {
#               query = "";
#             }
#             query += httpParameterName + "=" + parameters.get(httpParameterName);
#           }
  
#           return new URI(basePath.getScheme(), basePath.getUserInfo(), basePath.getHost(),basePath.getPort(), basePath.getPath(), query, basePath.getFragment());
#         } catch(Exception e) {
#           throw new EFhirClientException("Error appending http parameter", e);
#         }
#     }

  end
end
