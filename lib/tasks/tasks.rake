namespace :fhir do

  desc 'console'
  task :console, [] do |t, args|
    binding.pry
  end

  desc 'WIP to test the new API; delete when done'
  task :api_testing, [] do |t, args|

    client = FHIR::Client.new 'http://fhirtest.uhn.ca/baseDstu3'
    client2 = FHIR::Client.new 'http://sqlonfhir-may.azurewebsites.net/fhir'

    FHIR::Model.configure { |c| c.client = client }

    patient1 = FHIR::Patient.create(name: {given: 'Joe', family: 'Smith'})
    patient2 = FHIR::Patient.create(name: {given: 'Joe', family: 'Smith'}, client: client2)

    results = FHIR::Patient.where(given: 'Joe', family: 'Smith')
    results = FHIR::Patient.where(given: 'Joe', family: 'Smith', client: client2)

    patient1.save
    patient2.name[0].family = 'Smithfield'
    patient2.save

    patient_check = FHIR::Patient.find(patient1.id)
    patient_check = FHIR::Patient.find(patient1.id, client: client)

    patient3 = FHIR::Patient.new(name: {given: 'Sam', family: 'Jones'})
    patient3.save(client:client)
    patient4 = FHIR::Patient.new(name: {given: 'Sam', family: 'Jones'})
    patient4.save(client: client2)
    patient_check = FHIR::Patient.find(patient1.id)

    all_patients = FHIR::Patient.all()
    all_patients = FHIR::Patient.all(client: client2)

    # all_patients.count() # enumerable

    patient1.destroy
    patient2.destroy
    patient3.destroy

  end

  desc 'WIP to test the new API; delete when done'
  task :api_testing_noconfig, [] do |t, args|

    client = FHIR::Client.new 'http://fhirtest.uhn.ca/baseDstu3'
    patient = FHIR::Patient.create(name: {given: 'Joe', family: 'Smith'}, client: client)
    patient.destroy

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
  task :oauth2, [:url,:client_id,:client_secret] do |t, args|
    client = FHIR::Client.new(args.url)
    client_id = args.client_id
    client_secret = args.client_secret
    options = client.get_oauth2_metadata_from_conformance
    if options.empty?
      puts 'This server does not support the expected OAuth2 extensions.'
    else
      client.set_oauth2_auth(client_id,client_secret,options[:authorize_url],options[:token_url])
      reply = client.read_feed(FHIR::Patient)
      puts reply.body
    end
  end

  desc 'count all resources for a given server'
  task :count, [:url] do |t, args|
    client = FHIR::Client.new(args.url)
    counts = {}
    fhir_resources.map do | klass |
      reply = client.read_feed(klass)
      counts["#{klass.name.demodulize}"] = reply.resource.total unless reply.resource.nil?
    end
    printf "  %-30s %5s\n", 'Resource', 'Count'
    printf "  %-30s %5s\n", '--------', '-----'
    counts.each do |key,value|
      # puts "#{key}  #{value}"
      printf "  %-30s %5s\n", key, value
    end
  end

  desc 'delete all resources for a given server'
  task :clean, [:url] do |t, args|
    client = FHIR::Client.new(args.url)
    fhir_resources.map do | klass |
      reply = client.read_feed(klass)
      while !reply.nil? && !reply.resource.nil? && reply.resource.total > 0
        reply.resource.entry.each do |entry|
          client.destroy(klass,entry.resource.id) unless entry.resource.nil?
        end
        reply = client.read_feed(klass)
      end
    end
    Rake::Task['fhir:count'].invoke(args.url)
  end

  def fhir_resources
    Mongoid.models.select {|c| c.name.include?('FHIR') && !c.included_modules.find_index(FHIR::Resource).nil?}
  end

end
