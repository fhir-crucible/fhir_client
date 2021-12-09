require_relative '../test_helper'

class ReferencesExtrasTest < Test::Unit::TestCase

  def test_reference_id
    r = FHIR::Reference.new({'reference': 'Patient/foo'})
    assert r.reference_id == 'foo'
  end

  def test_reference_id_stu3
    r = FHIR::STU3::Reference.new({'reference': 'Patient/foo'})
    assert r.reference_id == 'foo'
  end

  def test_reference_id_dstu2
    r = FHIR::DSTU2::Reference.new({'reference': 'Patient/foo'})
    assert r.reference_id == 'foo'
  end

  def test_reference_contained
    r = FHIR::Reference.new({'reference': '#foo'})
    assert r.contained?
  end

  def test_reference_contained_stu3
    r = FHIR::STU3::Reference.new({'reference': '#foo'})
    assert r.contained?
  end

  def test_reference_contained_dstu2
    r = FHIR::DSTU2::Reference.new({'reference': '#foo'})
    assert r.contained?
  end

  def test_reference_type
    r = FHIR::Reference.new({'reference': 'Patient/foo'})
    assert r.resource_type == 'Patient'
  end

  def test_reference_type_stu3
    r = FHIR::STU3::Reference.new({'reference': 'Patient/foo'})
    assert r.resource_type == 'Patient'
  end

  def test_reference_type_dstu2
    r = FHIR::DSTU2::Reference.new({'reference': 'Patient/foo'})
    assert r.resource_type == 'Patient'
  end

  def test_reference_klass
    r = FHIR::Reference.new({'reference': 'Patient/foo'})
    assert r.resource_class == FHIR::Patient
  end

  def test_reference_klass_stu3
    r = FHIR::STU3::Reference.new({'reference': 'Patient/foo'})
    assert r.resource_class == FHIR::STU3::Patient
  end

  def test_reference_klass_dstu2
    r = FHIR::DSTU2::Reference.new({'reference': 'Patient/foo'})
    assert r.resource_class == FHIR::DSTU2::Patient
  end

  def test_relative
    r = FHIR::Reference.new({'reference': 'Patient/foo'})
    assert r.relative?
  end

  def test_relative_stu3
    r = FHIR::STU3::Reference.new({'reference': 'Patient/foo'})
    assert r.relative?
  end

  def test_relative_dstu2
    r = FHIR::DSTU2::Reference.new({'reference': 'Patient/foo'})
    assert r.relative?
  end

  def test_absolute
    r = FHIR::Reference.new({'reference': 'https://my-server.com/fhir/Patient/foo'})
    assert r.absolute?
  end

  def test_absolute_stu3
    r = FHIR::STU3::Reference.new({'reference': 'https://my-server.com/fhir/Patient/foo'})
    assert r.absolute?
  end

  def test_absolute_dstu2
    r = FHIR::DSTU2::Reference.new({'reference': 'https://my-server.com/fhir/Patient/foo'})
    assert r.absolute?
  end

  def test_read_contained
    stub_request(:get, /extras/).to_return(body: FHIR::Patient.new.to_json)
    client = FHIR::Client.new('extras')
    client.default_json
    FHIR::Model.client = client
    assert FHIR::Reference.new({'reference': '#foo'}).read.nil?
  end

  def test_read_reference_relative
    stub_request(:get, 'https://my-server.com/fhir/Patient/foo').to_return(body: FHIR::Patient.new.to_json)
    client = FHIR::Client.new('https://my-server.com/fhir')
    client.default_json
    FHIR::Model.client = client
    ref = FHIR::Reference.new({'reference': 'Patient/foo'})
    res = ref.read
    assert res.is_a?(FHIR::Patient)
  end

  def test_read_reference_absolute_same_base
    stub_request(:get, 'https://my-server.com/fhir/Patient/foo').to_return(body: FHIR::Patient.new.to_json)
    client = FHIR::Client.new('https://my-server.com/fhir')
    client.default_json
    FHIR::Model.client = client
    ref = FHIR::Reference.new({'reference': 'https://my-server.com/fhir/Patient/foo'})
    res = ref.read
    assert res.is_a?(FHIR::Patient)
    assert client == res.client
  end

  def test_read_reference_absolute_different_base
    stub_request(:get, 'https://external-server.com/fhir/Patient/foo').to_return(body: FHIR::Patient.new.to_json)
    client = FHIR::Client.new('https://my-server.com/fhir')
    client.default_json
    FHIR::Model.client = client
    ref = FHIR::Reference.new({'reference': 'https://external-server.com/fhir/Patient/foo'})
    res = ref.read
    assert res.is_a?(FHIR::Patient)
    assert client != res.client
  end

  def test_vread_reference
    stub_request(:get, 'https://my-server.com/fhir/Patient/foo/_history/6').to_return(body: FHIR::Patient.new.to_json)
    client = FHIR::Client.new('https://my-server.com/fhir')
    client.default_json
    FHIR::Model.client = client
    ref = FHIR::Reference.new({'reference': 'Patient/foo/_history/6'})
    res = ref.vread
    assert res.is_a?(FHIR::Patient)
  end

  def test_logical_reference
    ref = FHIR::Reference.new({'identifier': {'resourceType': 'Identifier'}})
    res = ref.read
    assert res.nil?
  end

  def test_reference_read_client
    reference_client = FHIR::Client.new('reference')
    model_client = FHIR::Client.new('model')

    ref = FHIR::Reference.new({'reference': 'Patient/foo'})
    ref.client = reference_client
    FHIR::Model.client = model_client

    request = stub_request(:get, /reference/)
    ref.read

    assert_requested(request)
  end

  def test_reference_read_optional_client
    reference_client = FHIR::Client.new('reference')
    custom_client = FHIR::Client.new('custom')

    ref = FHIR::Reference.new({'reference': 'Patient/foo'})
    ref.client = reference_client

    request = stub_request(:get, /custom/)
    ref.read(custom_client)

    assert_requested(request)
  end

  def test_reference_vread_optional_client
    reference_client = FHIR::Client.new('reference')
    custom_client = FHIR::Client.new('custom')

    ref = FHIR::Reference.new({'reference': 'Patient/foo/_history/1'})
    ref.client = reference_client

    request = stub_request(:get, /custom/)
    ref.vread(custom_client)

    assert_requested(request)
  end
end
