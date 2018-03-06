require 'fhir_client'
FHIR.logger.level = Logger::ERROR

namespace :fhir do
  desc 'console'
  task :console, [] do
    exec('ruby bin/console')
  end

  #
  # Prerequisites & Assumptions:
  #
  #  1. Running SMART-on-FHIR (DSTU2 branch) server  [http://example/fhir]
  #  2. Running OpenID Connect server [http://example:8080/openid-connect-server-webapp]
  #  3. Configured client under OpenID Connect server:
  #     a. Create a system scope if necessary. SMART-on-FHIR requires 'fhir_complete' scope.
  #     b. Add the scope created in (a) to client.
  #     c. Add the FHIR server URL to the list of allowed redirect URIs (required?)
  #     d. Ensure client has 'client credentials' grant type
  #     d. Whitelist the client
  #  4. 'client_id' and 'client_secret' variables are the name and secret of the client created in (3)
  #  5. :authorize_url is the authorization endpoint of the OpenID connect server
  #  6. :token_url is the token endpoint of the OpenID connect server
  #
  desc 'OAuth2 Example'
  task :oauth2, [:url, :client_id, :client_secret] do |_t, args|
    client = FHIR::Client.new(args.url)
    client_id = args.client_id
    client_secret = args.client_secret
    options = client.get_oauth2_metadata_from_conformance
    if options.empty?
      puts 'This server does not support the expected OAuth2 extensions.'
    else
      client.set_oauth2_auth(client_id, client_secret, options[:authorize_url], options[:token_url])
      reply = client.read_feed(FHIR::Patient)
      puts reply.body
    end
  end

  desc 'count all resources for a given server'
  task :count, [:url, :display_zero] do |_t, args|
    client = FHIR::Client.new(args.url)
    client.try_conformance_formats(FHIR::Formats::ResourceFormat::RESOURCE_JSON)
    display_zero = (args.display_zero == 'true')
    counts = {}
    fhir_resources.each do |klass|
      reply = client.read_feed(klass)
      if !reply.resource.nil? && (reply.resource.total > 0 || display_zero)
        counts[klass.name.demodulize.to_s] = reply.resource.total
      end
    end
    printf "  %-30s %5s\n", 'Resource', 'Count'
    printf "  %-30s %5s\n", '--------', '-----'
    counts.each do |key, value|
      # puts "#{key}  #{value}"
      printf "  %-30s %5s\n", key, value
    end
  end

  desc 'delete all resources for a given server'
  task :clean, [:url] do |_t, args|
    client = FHIR::Client.new(args.url)
    client.try_conformance_formats(FHIR::Formats::ResourceFormat::RESOURCE_JSON)
    fhir_resources.each do |klass|
      puts "Reading #{klass.name.demodulize}..."
      skipped = []
      reply = client.read_feed(klass)
      while !reply.nil? && !reply.resource.nil? && reply.resource.total > 0
        puts "  Cleaning #{reply.resource.entry.length} #{klass.name.demodulize} resources..."
        reply.resource.entry.each do |entry|
          unless entry.resource.nil?
            del_reply = client.destroy(klass, entry.resource.id)
            skipped << "#{klass.name.demodulize}/#{entry.resource.id}" if [405, 409].include?(del_reply.code)
          end
        end
        if skipped.empty?
          reply = client.read_feed(klass)
        else
          puts "  *** Unable to delete some #{klass.name.demodulize}s ***"
          reply = nil
        end
      end
    end
    puts 'Done cleaning.'
    Rake::Task['fhir:count'].invoke(args.url)
  end

  def fhir_resources
    FHIR::RESOURCES.map { |r| Object.const_get("FHIR::#{r}") }
  end
end
