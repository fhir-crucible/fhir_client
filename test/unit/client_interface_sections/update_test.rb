require_relative '../../test_helper'

class ClientInterfaceUpdateTest < Test::Unit::TestCase
  def client
    @client ||= FHIR::Client.new('update-test')
    @client.use_dstu2
    @client.default_json
    @client
  end

  # TODO: Is it okay if Connection & Host are included?
  # they weren't included before and delete
  def check_header_keys(reply)
    keys = reply.request[:headers].keys
    assert keys.include? 'Content-Type'

    keys.delete_if {|x| /\AAccept\z|\AAccept-Charset\z|\AAccept\z|\AConnection\z|\AContent-Type\z|\AHost\z|\APrefer\z|\AIf-Match\z|\AUser-Agent\z/.match? x}
    assert keys.empty?
  end

  def test_class_partial_update
    FHIR::Model.client = client
    patient = FHIR::Patient.new({'id' => 'foo', 'active'=>true})
    patchset = [
        {
          op: "replace",
          path: "/active/",
          value: "false"
        }
      ]

    outcome = FHIR::OperationOutcome.new({'issue'=>[{'code'=>'informational', 'severity'=>'information', 'diagnostics'=>'Successfully updated "Patient/foo" in 0 ms'}]})

    stub_request(:patch, "http://update-test/Patient/foo").
    with(
      body: "\"[{\\\"op\\\":\\\"replace\\\",\\\"path\\\":\\\"/active/\\\",\\\"value\\\":\\\"false\\\"}]\"",
      headers: {
  	  'Accept'=>'application/json+fhir',
  	  'Accept-Charset'=>'utf-8',
  	  'Connection'=>'close',
  	  'Content-Type'=>'application/json-patch+json',
  	  'Host'=>'update-test',
  	  'User-Agent'=>'Ruby FHIR Client'
      }).
    to_return(status: 200, body: outcome.to_json, headers: {'Content-Type'=>'application/fhir+json', 'Location'=>'http://update-test/Patient/foo/_history/0', 'ETag'=>'W/"foo"', 'Last-Modified'=>Time.now.strftime("%a, %e %b %Y %T %Z")})

    reply = FHIR::Patient.partial_update(patient.id, patchset)
    assert reply.is_a?(FHIR::DSTU2::OperationOutcome)
  end

  def test_update
    FHIR::Model.client = client
    patient = FHIR::Patient.new({'id' => 'foo', 'active'=>true})
    stub_request(:put, /update-test\/Patient\/foo/).with(headers: {'Content-Type'=>'application/json+fhir;charset=utf-8'}).to_return(status: 200)
    reply = client.update(patient, 'foo')
    check_header_keys reply
    assert reply.code == 200
  end

  def test_version_aware_update
    FHIR::Model.client = client
    patient = FHIR::Patient.new({'id' => 'foo', 'active'=>true})
    stub_request(:put, /update-test\/Patient\/foo/).with(headers: {'If-Match'=>'W/2'}).to_return(status: 200)
    reply = client.version_aware_update(patient, 'foo', 2)
    check_header_keys reply
    assert reply.code == 200
  end

end
