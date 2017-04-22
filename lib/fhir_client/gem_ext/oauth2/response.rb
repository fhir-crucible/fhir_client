require 'oauth2/response'

module OAuth2
  class Response
    @@content_types = {
      'application/json' => :json,
      'application/fhir+json' => :json,
      'text/javascript' => :json,
      'application/x-www-form-urlencoded' => :query,
      'text/plain' => :text
    }
  end
end

# Add application/fhir+xml
OAuth2::Response.register_parser(:xml, ['text/xml', 'application/rss+xml', 'application/rdf+xml', 'application/atom+xml', 'application/fhir+xml']) do |body|
  MultiXml.parse(body) rescue body
end
