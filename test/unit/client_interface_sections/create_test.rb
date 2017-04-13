require_relative '../../test_helper'

class ClientInterfaceCreateTest < Test::Unit::TestCase
  def client
    @client ||= FHIR::Client.new('create-test')
  end

  def test_create_response_properly_parsed_xml
    patient = FHIR::Patient.new({'gender'=>'female', 'active'=>true, 'deceasedBoolean'=>false})
    outcome = FHIR::OperationOutcome.new({'issue'=>[{'code'=>'informational', 'severity'=>'information', 'diagnostics'=>'Successfully created "Patient/foo" in 0 ms'}]})

    stub_request(:post, /create-test/).to_return(body: outcome.to_xml, headers: {'Content-Type'=>'application/fhir+xml', 'Content-Location'=>'Patient/foo/_history/0'})
    reply = client.create(patient)
    assert reply.resource.is_a?(FHIR::OperationOutcome)
    assert reply.resource_class == FHIR::Patient
    assert reply.id == 'foo'
  end

  def test_create_response_properly_parsed_json
    patient = FHIR::Patient.new({'gender'=>'female', 'active'=>true, 'deceasedBoolean'=>false})
    outcome = FHIR::OperationOutcome.new({'issue'=>[{'code'=>'informational', 'severity'=>'information', 'diagnostics'=>'Successfully created "Patient/foo" in 0 ms'}]})

    stub_request(:post, /create-test/).to_return(body: outcome.to_json, headers: {'Content-Type'=>'application/fhir+json', 'Content-Location'=>'Patient/foo/_history/0'})
    reply = client.create(patient)
    assert reply.resource.is_a?(FHIR::OperationOutcome)
    assert reply.resource_class == FHIR::Patient
    assert reply.id == 'foo'
  end

  def test_create_response_blank
    patient = FHIR::Patient.new({'gender'=>'female', 'active'=>true, 'deceasedBoolean'=>false})

    stub_request(:post, /create-test/).to_return(headers: {'Content-Location'=>'Patient/foo/_history/0'})
    reply = client.create(patient)
    assert reply.resource.is_a?(FHIR::Patient)
    assert reply.resource_class == FHIR::Patient
    assert reply.id == 'foo'
  end

  def test_read
    patient = FHIR::Patient.new({'gender'=>'female', 'active'=>true, 'deceasedBoolean'=>false})

    stub_request(:get, /create-test/).to_return(body: patient.to_json, headers: {'Content-Type'=>'application/fhir+json', 'Content-Location'=>'Patient/foo/_history/0'})
    reply = client.read(FHIR::Patient,'foo')
    assert reply.resource.is_a?(FHIR::Patient)
    assert reply.resource_class == FHIR::Patient
    assert reply.id == 'foo'
  end

end
