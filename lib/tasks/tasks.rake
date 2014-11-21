namespace :fhir do

  desc 'console'
  task :console, [] do |t, args|
    binding.pry
  end

end
