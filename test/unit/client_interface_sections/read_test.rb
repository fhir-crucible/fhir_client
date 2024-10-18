require_relative '../../test_helper'
class ClientInterfaceReadTest < Test::Unit::TestCase
  def client
    @client ||= FHIR::Client.new('read-test')
  end

  def check_header_keys(reply)
    keys = reply.request[:headers].keys

    keys.delete_if {|x| /\AAccept\z|\AAccept-Charset\z|\AAccept\z|\AIf-Match\z|\AUser-Agent\z|\AETag\z|\AIf-Modified-Since\z|\AIf-None-Match\z/.match? x}
    assert keys.empty?
  end

  def test_read
    patient = FHIR::Patient.new({'gender'=>'female', 'active'=>true, 'deceasedBoolean'=>false})
    stub_request(:get, /read-test/).to_return(status: 200, body: patient.to_json, headers: {'Content-Type'=>'application/fhir+json', 'ETag'=>'W/"foo"', 'Last-Modified'=>Time.now.strftime("%a, %e %b %Y %T %Z")})
    temp = client
    temp.use_r4
    temp.default_json
    reply = temp.read(FHIR::Patient,'foo')
    assert reply.resource.is_a?(FHIR::Patient)
    assert reply.resource_class == FHIR::Patient
    assert reply.id == 'foo'
    check_header_keys reply
    assert reply.is_valid?
  end

  def test_vread
    patient = FHIR::Patient.new({'gender'=>'female', 'active'=>true, 'deceasedBoolean'=>false})
    stub_request(:get, /read-test\/.*_history\/2/).to_return(status: 200, body: patient.to_json, headers: {'Content-Type'=>'application/fhir+json', 'ETag'=>'W/"foo"', 'Last-Modified'=>Time.now.strftime("%a, %e %b %Y %T %Z")})
    temp = client
    temp.use_r4
    temp.default_json
    reply = temp.vread(FHIR::Patient,'foo', 2)
    assert reply.resource.is_a?(FHIR::Patient)
    assert reply.resource_class == FHIR::Patient
    assert reply.id == 'foo'
    check_header_keys reply
    # The versionId should be checked
    #assert reply.meta.versionId = 2
    # Validation assumes vread is a history interaction as well in the path regex
    #assert reply.is_valid?
  end

  def test_conditional_read_since
    patient = FHIR::Patient.new({'gender'=>'female', 'active'=>true, 'deceasedBoolean'=>false})
    stub_request(:get, /read-test/).with(headers: {'If-Modified-Since' => 'Wed, 21 Oct 2015 07:28:00 GMT'}).to_return(status: 200, body: patient.to_json, headers: {'Content-Type'=>'application/fhir+json', 'ETag'=>'W/"foo"', 'Last-Modified'=>Time.now.strftime("%a, %e %b %Y %T %Z")})
    temp = client
    temp.use_r4
    temp.default_json
    reply = temp.conditional_read_since(FHIR::Patient,'foo', 'Wed, 21 Oct 2015 07:28:00 GMT')
    assert reply.resource.is_a?(FHIR::Patient)
    assert reply.resource_class == FHIR::Patient
    assert reply.id == 'foo'
    check_header_keys reply
  end

  def test_conditional_read_version
    patient = FHIR::Patient.new({'gender'=>'female', 'active'=>true, 'deceasedBoolean'=>false})
    stub_request(:get, /read-test/).with(headers: {'If-None-Match' => 'W/ABC'}).to_return(status: 200, body: patient.to_json, headers: {'Content-Type'=>'application/fhir+json', 'ETag'=>'W/"foo"', 'Last-Modified'=>Time.now.strftime("%a, %e %b %Y %T %Z")})
    temp = client
    temp.use_r4
    temp.default_json
    reply = temp.conditional_read_version(FHIR::Patient,'foo','ABC')
    assert reply.resource.is_a?(FHIR::Patient)
    assert reply.resource_class == FHIR::Patient
    assert reply.id == 'foo'
    check_header_keys reply
  end

  def test_raw_read
    patient = FHIR::Patient.new({'gender'=>'female', 'active'=>true, 'deceasedBoolean'=>false})
    stub_request(:get, /read-test/)
        .to_return(status: 200,
                   body: patient.to_json,
                   headers: {'Content-Type'=>'application/fhir+json',
                             'ETag'=>'W/"foo"',
                             'Last-Modified'=>Time.now.strftime("%a, %e %b %Y %T %Z")})
    temp = client
    temp.use_r4
    temp.default_json
    options = {resource: FHIR::Patient, id: 'foo'}
    reply = temp.raw_read(options)
    returned_resource = temp.parse_reply(FHIR::Patient, FHIR::Formats::ResourceFormat::RESOURCE_JSON, reply)
    assert returned_resource.is_a?(FHIR::Patient)
    assert returned_resource.gender == 'female'
  end
end