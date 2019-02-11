require_relative '../test_helper'

class TestUnitCustomException < ClientException ; end

class ModelTest < Test::Unit::TestCase

  def test_default_instance_exception
    stub_request(:post, /create/).to_return(status: 403, body: "")
    client = FHIR::Client.new('create')
    client.default_json
    FHIR::Model.client = client

    assert_raise ClientException do
      FHIR::Patient.new({'id':'foo'}).create
    end
  end

  def test_custom_instance_exception
    stub_request(:post, /create/).to_return(status: 403, body: "")
    client = FHIR::Client.new('create')
    client.default_json
    client.exception_class = TestUnitCustomException
    FHIR::Model.client = client

    assert_raise TestUnitCustomException do
      FHIR::Patient.new({'id':'foo'}).create
    end
  end

  def test_default_class_exception
    stub_request(:post, /create/).to_return(status: 403, body: "")
    client = FHIR::Client.new('create')
    client.default_json
    FHIR::Model.client = client

    assert_raise ClientException do
      FHIR::Patient.create({'id':'foo'})
    end
  end

  def test_custom_class_exception
    stub_request(:post, /create/).to_return(status: 403, body: "")
    client = FHIR::Client.new('create')
    client.default_json
    client.exception_class = TestUnitCustomException
    FHIR::Model.client = client

    assert_raise TestUnitCustomException do
      FHIR::Patient.create({'id':'foo'})
    end
  end

end

