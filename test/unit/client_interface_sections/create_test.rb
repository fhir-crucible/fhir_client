require_relative '../../test_helper'

class ClientInterfaceCreateTest < Test::Unit::TestCase
  def client
    @client ||= FHIR::Client.new('create-test')
  end

  def test_create_response_properly_parsed_xml
    patient = FHIR::Patient.new({'gender'=>'female', 'active'=>true, 'deceasedBoolean'=>false})
    outcome = FHIR::OperationOutcome.new({'issue'=>[{'code'=>'informational', 'severity'=>'information', 'diagnostics'=>'Successfully created "Patient/foo" in 0 ms'}]})

    stub_request(:post, /create-test/).to_return(status: 201, body: outcome.to_xml, headers: {'Content-Type'=>'application/fhir+xml', 'Location'=>'http://create-test/Patient/foo/_history/0', 'ETag'=>'W/"foo"', 'Last-Modified'=>Time.now.strftime("%a, %e %b %Y %T %Z")})
    reply = client.create(patient)
    assert reply.resource.is_a?(FHIR::OperationOutcome)
    assert reply.resource_class == FHIR::Patient
    assert reply.id == 'foo'
    assert reply.version == '0'
    assert reply.is_valid?
  end

  def test_create_response_properly_parsed_json
    patient = FHIR::Patient.new({'gender'=>'female', 'active'=>true, 'deceasedBoolean'=>false})
    outcome = FHIR::OperationOutcome.new({'issue'=>[{'code'=>'informational', 'severity'=>'information', 'diagnostics'=>'Successfully created "Patient/foo" in 0 ms'}]})

    stub_request(:post, /create-test/).to_return(status: 201, body: outcome.to_json, headers: {'Content-Type'=>'application/fhir+json', 'Location'=>'http://create-test/Patient/foo/_history/0', 'ETag'=>'W/"foo"', 'Last-Modified'=>Time.now.strftime("%a, %e %b %Y %T %Z")})
    reply = client.create(patient)
    assert reply.resource.is_a?(FHIR::OperationOutcome)
    assert reply.resource_class == FHIR::Patient
    assert reply.id == 'foo'
    assert reply.version == '0'
    assert reply.is_valid?
  end

  def test_create_response_blank
    patient = FHIR::Patient.new({'gender'=>'female', 'active'=>true, 'deceasedBoolean'=>false})

    stub_request(:post, /create-test/).to_return(status: 201, headers: {'Location'=>'http://create-test/Patient/foo/_history/0', 'ETag'=>'W/"foo"', 'Last-Modified'=>Time.now.strftime("%a, %e %b %Y %T %Z")})
    reply = client.create(patient)
    assert reply.resource.is_a?(FHIR::Patient)
    assert reply.resource_class == FHIR::Patient
    assert reply.id == 'foo'
    assert reply.version == '0'
    assert !reply.is_valid? # reply isn't valid because a response should have been included
  end

  def test_read
    patient = FHIR::Patient.new({'gender'=>'female', 'active'=>true, 'deceasedBoolean'=>false})

    stub_request(:get, /create-test/).to_return(status: 200, body: patient.to_json, headers: {'Content-Type'=>'application/fhir+json', 'ETag'=>'W/"foo"', 'Last-Modified'=>Time.now.strftime("%a, %e %b %Y %T %Z")})
    temp = client
    temp.use_stu3
    temp.default_json
    reply = temp.read(FHIR::Patient,'foo')
    assert reply.resource.is_a?(FHIR::Patient)
    assert reply.resource_class == FHIR::Patient
    assert reply.id == 'foo'
    assert !reply.is_valid? # technically, the READ Request should not have a Content-Type, it should use an Accept
  end

end
