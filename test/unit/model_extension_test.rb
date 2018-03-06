require_relative '../test_helper'

class ModelExtensionTest < Test::Unit::TestCase

  def test_create_model_extension
    stub_request(:post, /create/).to_return(status: 201, body: FHIR::Patient.new({ 'id': 'foo' }).to_json)
    client = FHIR::Client.new('create')
    client.default_json
    FHIR::Model.client = client
    FHIR::Patient.new({'id':'foo'}).create
    assert_equal '201', client.reply.response[:code].to_s
  end

  def test_create_model_extension_dstu2
    stub_request(:post, /create/).to_return(status: 201, body: FHIR::DSTU2::Patient.new({ 'id': 'foo' }).to_json)
    client = FHIR::Client.new('create')
    client.default_json
    client.use_dstu2
    FHIR::DSTU2::Model.client = client
    FHIR::DSTU2::Patient.new({'id':'foo'}).create
    assert_equal '201', client.reply.response[:code].to_s
  end
end

