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
    assert_equal :stu3, client.fhir_version
    assert client.read(FHIR::Patient, 'foo').resource.is_a?(FHIR::Patient)
  end

  def test_dstu2_patient_manual
    stub_request(:get, /dstu2/).to_return(body: FHIR::DSTU2::Patient.new({ 'id': 'foo' }).to_json)
    client = FHIR::Client.new('dstu2')
    client.default_json
    client.use_dstu2
    assert_equal :dstu2, client.fhir_version
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

  def test_dstu2_reply_fhir_version
    stub_request(:get, /dstu2/).to_return(body: FHIR::DSTU2::Patient.new({ 'id': 'foo' }).to_json)
    client = FHIR::Client.new('dstu2')
    client.default_json
    client.use_dstu2
    FHIR::DSTU2::Model.client = client
    patient = FHIR::DSTU2::Patient.read('foo')
    assert_equal :dstu2, client.reply.fhir_version
  end

  def test_stu3_reply_fhir_version
    stub_request(:get, /stu3/).to_return(body: FHIR::Patient.new({ 'id': 'foo' }).to_json)
    client = FHIR::Client.new('stu3')
    client.default_json
    FHIR::Model.client = client
    patient = FHIR::Patient.read('foo')
    assert_equal :stu3, client.reply.fhir_version
  end

  def test_stu3_accept_mime_type_json
    stub_request(:get, /stu3/).to_return(body: FHIR::Patient.new({'id': 'foo'}).to_json)
    client = FHIR::Client.new('stu3')
    client.default_json
    assert_equal :stu3, client.fhir_version
    assert_equal 'application/fhir+json', client.read(FHIR::Patient, 'foo').request[:headers]['Accept']
  end

  def test_stu3_content_type_mime_type_json
    stub_request(:post, /stu3/).to_return(body: FHIR::Patient.new({'id': 'foo'}).to_json)
    client = FHIR::Client.new('stu3')
    client.default_json
    assert_equal :stu3, client.fhir_version
    assert client.create(FHIR::Patient.new({'id': 'foo'})).request[:headers]['Content-Type'].include?('application/fhir+json')
  end

  def test_dstu2_accept_mime_type_json
    stub_request(:get, /dstu2/).to_return(body: FHIR::DSTU2::Patient.new({'id': 'foo'}).to_json)
    client = FHIR::Client.new('dstu2')
    client.default_json
    client.use_dstu2
    assert_equal :dstu2, client.fhir_version
    # dstu2 fhir type was changed in stu3
    assert_equal 'application/json+fhir', client.read(FHIR::DSTU2::Patient, 'foo').request[:headers]['Accept']
  end

  def test_dstu2_content_type_mime_type_json
    stub_request(:post, /dstu2/).to_return(body: FHIR::DSTU2::Patient.new({'id': 'foo'}).to_json)
    client = FHIR::Client.new('dstu2')
    client.default_json
    client.use_dstu2
    assert_equal :dstu2, client.fhir_version
    # dstu2 fhir type was changed in stu3
    assert client.create(FHIR::DSTU2::Patient.new({'id': 'foo'})).request[:headers]['Content-Type'].include?('application/json+fhir')
  end

  def test_stu3_accept_mime_type_xml
    stub_request(:get, /stu3/).to_return(body: FHIR::Patient.new({'id': 'foo'}).to_xml)
    client = FHIR::Client.new('stu3')
    client.default_xml
    assert_equal :stu3, client.fhir_version
    assert_equal 'application/fhir+xml', client.read(FHIR::Patient, 'foo').request[:headers]['Accept']
  end

  def test_stu3_content_type_mime_type_xml
    stub_request(:post, /stu3/).to_return(body: FHIR::Patient.new({'id': 'foo'}).to_xml)
    client = FHIR::Client.new('stu3')
    client.default_xml
    assert_equal :stu3, client.fhir_version
    assert client.create(FHIR::Patient.new({'id': 'foo'})).request[:headers]['Content-Type'].include?('application/fhir+xml')
  end

  def test_dstu2_accept_mime_type_xml
    stub_request(:get, /dstu2/).to_return(body: FHIR::DSTU2::Patient.new({'id': 'foo'}).to_xml)
    client = FHIR::Client.new('dstu2')
    client.default_xml
    client.use_dstu2
    assert_equal :dstu2, client.fhir_version
    # dstu2 fhir type was changed in stu3
    assert_equal 'application/xml+fhir', client.read(FHIR::DSTU2::Patient, 'foo').request[:headers]['Accept']
  end

  def test_dstu2_content_type_mime_type_xml
    stub_request(:post, /dstu2/).to_return(body: FHIR::DSTU2::Patient.new({'id': 'foo'}).to_xml)
    client = FHIR::Client.new('dstu2')
    client.default_xml
    client.use_dstu2
    assert_equal :dstu2, client.fhir_version
    # dstu2 fhir type was changed in stu3
    assert client.create(FHIR::DSTU2::Patient.new({'id': 'foo'})).request[:headers]['Content-Type'].include?('application/xml+fhir')
  end
end
