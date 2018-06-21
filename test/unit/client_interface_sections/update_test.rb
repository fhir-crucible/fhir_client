require_relative '../../test_helper'

class ClientInterfaceUpdateTest < Test::Unit::TestCase
  def client
    @client ||= FHIR::Client.new('update-test')
  end

  def test_class_partial_update
    patient = FHIR::Patient.new({'id' => 'foo', 'active'=>true})
    patchset = [
        {
          op: "replace",
          path: "/active/",
          value: "false"
        }
      ]

    outcome = FHIR::OperationOutcome.new({'issue'=>[{'code'=>'informational', 'severity'=>'information', 'diagnostics'=>'Successfully updated "Patient/foo" in 0 ms'}]})

    stub_request(:patch, /Patient\/foo/).with(body: "[{\"op\":\"replace\",\"path\":\"/active/\",\"value\":\"false\"}]").to_return(status: 200, body: outcome.to_json, headers: {'Content-Type'=>'application/fhir+json', 'Location'=>'http://update-test/Patient/foo/_history/0', 'ETag'=>'W/"foo"', 'Last-Modified'=>Time.now.strftime("%a, %e %b %Y %T %Z")})
    reply = FHIR::Patient.partial_update(patient.id, patchset)

    assert reply.is_a?(FHIR::DSTU2::OperationOutcome)
  end

end
