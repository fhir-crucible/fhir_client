require_relative '../../test_helper'

class ClientInterfaceOperationTest < Test::Unit::TestCase
  def client
    @client ||= FHIR::Client.new('operation-test')
  end

  def test_match_operation
    stub_request(:post, 'operation-test/Patient/$match').to_return(status: 200, body: '{}', headers: {'Content-Type'=>FHIR::Formats::ResourceFormat::RESOURCE_JSON, 'ETag'=>'W/"foo"', 'Last-Modified'=>Time.now.strftime("%a, %e %b %Y %T %Z")})


    patient = FHIR::Patient.new({'name'=>[{ 'family' => 'Chalmers'}]});

    reply = client.match(patient, {matchCount: 5, onlyCertainMatches: false}, FHIR::Formats::ResourceFormat::RESOURCE_JSON)

    request_params = FHIR::Json.from_json(reply.request[:payload])
    assert request_params.class == FHIR::Parameters
    assert reply.request[:method] == :post
    assert reply.request[:headers]["Content-Type"].include?(FHIR::Formats::ResourceFormat::RESOURCE_JSON)
    assert request_params.parameter.any?{|p| p.name == 'resource' && p.resource.try(:class) == FHIR::Patient}
    assert request_params.parameter.any?{|p| p.name == 'count' && p.valueInteger == 5}
    assert request_params.parameter.any?{|p| p.name == 'onlyCertainMatches' && p.valueBoolean == false}

  end

end
