# FHIR Client [![Build Status](https://travis-ci.org/fhir-crucible/fhir_client.svg?branch=master)](https://travis-ci.org/fhir-crucible/fhir_client)

Ruby FHIR client.

Supports:
* FHIR STU3
* XML and JSON
* All CRUD, including version read and history
* Transactions and Batches
* Search
* Operations (e.g. `$everything`, `$validate`)
* Support for OAuth2

## Getting Started

    $ bundle install
    $ bundle exec rake fhir:console

## Creating a Client
```ruby
client = FHIR::Client.new(url)
```

This client supports two modes of operation: basic and advanced.  The basic mode is useful for simple operations
because it promotes an ActiveRecord-like style of interaction.  The advanced mode is less developer-friendly, but is currently necessary if you would like to use the entire range of operations exposed by FHIR.

## Basic Usage

Associate the client with the model:

```ruby
FHIR::Model.client = client
```

The FHIR models can now be used to directly interact with a FHIR server.

```ruby
# read an existing patient with an ID of 'example'
patient = FHIR::Patient.read('example')

# update a patient
patient.gender = 'female'
patient.update # saves the patient

# create a patient
patient = FHIR::Patient.create(name: {given: 'John', family: 'Doe'})

#create a patient with specific headers
patient = FHIR::Patient.new(name: {given: 'John', family: 'Doe'}).create({Prefer: "return=representation"})

# search patients
results = FHIR::Patient.search(given: 'John', family: 'Doe')
results.count # results in an enumeration

# delete the recently created patient
patient.destroy
```

## Advanced Usage

### CRUD Examples
```ruby
# read an existing patient with id "example"
patient = client.read(FHIR::Patient, "example").resource

# read specifying Formats
patient = client.read(FHIR::Patient, "example", FHIR::Formats::FeedFormat::FEED_JSON).resource

# create a patient
patient = FHIR::Patient.new
patient_id = client.create(patient).id

# update the patient
patient.gender = 'female'
client.update(patient, patient_id)

# conditional update
p_identifier = FHIR::Identifier.new
p_identifier.use = 'official'
p_identifier.system = 'http://projectcrucible.org'
p_identifier.value = '123'
patient.identifier = [ p_identifier ]
searchParams = { :identifier => 'http://projectcrucible.org|123' }
client.conditional_update(patient, patient_id, searchParams)

# conditional create
ifNoneExist = { :identifier => 'http://projectcrucible.org|123' }
client.conditional_create(patient, ifNoneExist)

# destroy the patient
client.destroy(FHIR::Patient, patient_id)
```

### Searching
```ruby
reply = client.search(FHIR::Patient, search: {parameters: {name: 'P'}})
bundle = reply.resource
patient = bundle.entry.first.resource
```

### Fetching a Bundle
```ruby
reply = client.read_feed(FHIR::Patient) # fetch Bundle of Patients
bundle = reply.resource
bundle.entry.each do |entry|
  patient = entry.resource
  puts patient.name[0].text
end
puts reply.code # HTTP 200 (or whatever was returned)
puts reply.body # Raw XML or JSON
```

### Transactions
```ruby
# Create a patient
@patient = FHIR::Patient.new
@patient.id = 'temporary_id'

# Create an observation
@observation = FHIR::Observation.new
@observation.status = 'final'
@coding = FHIR::Coding.new
@coding.system = 'http://loinc.org'
@coding.code='8302-2'
@observation.code = FHIR::CodeableConcept.new
@observation.code.coding = [ @coding ]
@quantity = FHIR::Quantity.new
@quantity.value = 170
@quantity.unit = 'cm'
@quantity.system = 'http://unitsofmeasure.org'
@observation.valueQuantity = @quantity
@reference = FHIR::Reference.new
@reference.reference = "Patient/#{@patient.id}"
@observation.subject = @reference

# Submit them both as a transaction
@client.begin_transaction
@client.add_transaction_request('POST',nil,@patient)
@client.add_transaction_request('POST',nil,@observation)
reply = @client.end_transaction
```

### OAuth2 Support
```ruby
client = FHIR::Client.new(url)
client_id = 'example'
client_secret = 'secret'
options = client.get_oauth2_metadata_from_conformance
if options.empty?
  puts 'This server does not support the expected OAuth2 extensions.'
else
  client.set_oauth2_auth(client_id,client_secret,options[:site],options[:authorize_url],options[:token_url])
  reply = client.read_feed(FHIR::Patient)
  puts reply.body
end
```

# License

Copyright 2014-2016 The MITRE Corporation

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
