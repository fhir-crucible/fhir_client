# FHIR Client [![Build Status](https://travis-ci.org/fhir-crucible/fhir_client.svg?branch=master)](https://travis-ci.org/fhir-crucible/fhir_client)

Ruby FHIR client.

Supports:
* XML and JSON
* All CRUD, including version read and history
* Search
* Operations (e.g. `$everything`, `$validate`)
* Support for OAuth2

### Getting Started

    $ bundle install
    $ bundle exec rake fhir:console

### Creating a Client

    client = FHIR::Client.new(url)

### Fetching a Bundle

    reply = client.read_feed(FHIR::Patient) # fetch Bundle of Patients
    puts reply.body

### CRUD Examples

    # read an existing patient with id "example"
    patient = client.read(FHIR::Patient, "example")
    patient = client.read(FHIR::Patient, "example", FHIR::Formats::ResourceFormat::RESOURCE_JSON) # specifying Formats

    # update the patient
    patient.gender = 'female'
    client.update(patient, patient.xmlId)

    # destroy the patient
    client.destroy(FHIR::Patient, patient.xmlId)

### OAuth2 Support

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

# DSTU2

Updated to support the FHIR [DSTU2 branch](http://hl7.org/fhir-develop).

# License

Copyright 2014 The MITRE Corporation

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
