require_relative '../test_helper'

class MultiversionTest < Test::Unit::TestCase

  def test_autodetect_stu3
    root = File.expand_path '..', File.dirname(File.absolute_path(__FILE__))
    capabilitystatement = File.read(File.join(root, 'fixtures', 'capabilitystatement.json'))
    stub_request(:get, /autodetect/).to_return(body: capabilitystatement)
    client = FHIR::Client.new('autodetect')
    client.default_json
    assert client.detect_version == :stu3
  end

  def test_autodetect_dstu2
    root = File.expand_path '..', File.dirname(File.absolute_path(__FILE__))
    conformance = File.read(File.join(root, 'fixtures', 'conformance.json'))
    stub_request(:get, /autodetect/).to_return(body: conformance)
    client = FHIR::Client.new('autodetect')
    client.default_json
    assert client.detect_version == :dstu2
  end

  def test_stu3_patient_manual
    stub_request(:get, /stu3/).to_return(body: FHIR::Patient.new.to_json)
    client = FHIR::Client.new('stu3')
    client.default_json
    assert client.read(FHIR::Patient, 'foo').resource.is_a?(FHIR::Patient)
  end

  def test_dstu2_patient_manual
    stub_request(:get, /dstu2/).to_return(body: FHIR::DSTU2::Patient.new({ 'id': 'foo' }).to_json)
    client = FHIR::Client.new('dstu2')
    client.default_json
    client.use_dstu2
    assert client.read(FHIR::DSTU2::Patient, 'foo').resource.is_a?(FHIR::DSTU2::Patient)
  end

  def test_stu3_patient_klass_access
    stub_request(:get, /stu3/).to_return(body: FHIR::Patient.new.to_json)
    client = FHIR::Client.new('stu3')
    client.default_json
    FHIR::Model.client = client
    assert FHIR::Patient.read('foo').is_a?(FHIR::Patient)
  end

  def test_dstu2_patient_klass_access
    stub_request(:get, /dstu2/).to_return(body: FHIR::DSTU2::Patient.new({ 'id': 'foo' }).to_json)
    client = FHIR::Client.new('dstu2')
    client.default_json
    client.use_dstu2
    FHIR::DSTU2::Model.client = client
    assert FHIR::DSTU2::Patient.read('foo').is_a?(FHIR::DSTU2::Patient)
  end

end
