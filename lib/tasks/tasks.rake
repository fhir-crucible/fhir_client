namespace :fhir do

  desc 'console'
  task :console, [] do |t, args|
    binding.pry
  end

  desc 'count all resources for a given server'
  task :count, [:url] do |t, args|
    client = FHIR::Client.new(args.url)
    counts = {}
    fhir_resources.map do | klass |
      reply = client.read_feed(klass)
      counts["#{klass.name.demodulize}"] = reply.resource.total
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
      while reply != nil && reply.resource.total > 0
        reply.resource.entry.each do |entry|
          client.destroy(klass,entry.resource.xmlId)
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
