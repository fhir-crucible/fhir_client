require_relative '../test_helper'

class ReferencesExtrasTest < Test::Unit::TestCase

  def test_reference_id
    r = FHIR::Reference.new({'reference': 'Patient/foo'})
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

  def test_reference_contained_dstu2
    r = FHIR::DSTU2::Reference.new({'reference': '#foo'})
    assert r.contained?
  end

  def test_reference_type
    r = FHIR::Reference.new({'reference': 'Patient/foo'})
    assert r.type == 'Patient'
  end

  def test_reference_type_dstu2
    r = FHIR::DSTU2::Reference.new({'reference': 'Patient/foo'})
    assert r.type == 'Patient'
  end

  def test_reference_klass
    r = FHIR::Reference.new({'reference': 'Patient/foo'})
    assert r.resource_class == FHIR::Patient
  end

  def test_reference_klass_dstu2
    r = FHIR::DSTU2::Reference.new({'reference': 'Patient/foo'})
    assert r.resource_class == FHIR::DSTU2::Patient
  end

  def test_relative
    r = FHIR::Reference.new({'reference': 'Patient/foo'})
    assert r.relative?
  end

  def test_relative_dstu2
    r = FHIR::DSTU2::Reference.new({'reference': 'Patient/foo'})
    assert r.relative?
  end

  def test_absolute
    r = FHIR::Reference.new({'reference': 'http://hapi.fhir.org/baseDstu3/Patient/foo'})
    assert r.absolute?
  end

  def test_absolute_dstu2
    r = FHIR::DSTU2::Reference.new({'reference': 'http://hapi.fhir.org.baseDstu2/Patient/foo'})
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

end
