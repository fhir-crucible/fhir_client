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

  def test_dstu2_transaction
    stub_request(:post, /dstu2/).to_return(body: FHIR::DSTU2::Bundle.new({'id': 'foo'}).to_xml)
    client = FHIR::Client.new('dstu2')
    client.default_xml
    client.use_dstu2
    client.begin_transaction
    client.add_transaction_request('GET', 'Patient/foo')
    client.add_transaction_request('POST', nil, FHIR::DSTU2::Observation.new({'id': 'foo'}))
    reply = client.end_transaction
    assert_equal :dstu2, reply.fhir_version
    assert_equal 'application/xml+fhir', reply.request[:headers]['Accept']
    assert reply.resource.is_a?(FHIR::DSTU2::Bundle)
  end

  def test_stu3_transaction
    stub_request(:post, /stu3/).to_return(body: FHIR::Bundle.new({'id': 'foo'}).to_xml)
    client = FHIR::Client.new('stu3')
    client.default_xml
    client.begin_transaction
    client.add_transaction_request('GET', 'Patient/foo')
    client.add_transaction_request('POST', nil, FHIR::Observation.new({'id': 'foo'}))
    reply = client.end_transaction
    assert_equal :stu3, reply.fhir_version
    assert_equal 'application/fhir+xml', reply.request[:headers]['Accept']
    assert reply.resource.is_a?(FHIR::Bundle)
  end

  def test_dstu2_patient_record
    bundle = FHIR::DSTU2::Bundle.new({'id': 'foo'})
    bundle.entry << FHIR::DSTU2::Bundle::Entry.new
    bundle.entry.last.resource = FHIR::DSTU2::Patient.new({'id': 'example-patient'})
    stub_request(:get, 'http://dstu2/Patient/example-patient/$everything').to_return(body: bundle.to_xml)
    client = FHIR::Client.new('dstu2')
    client.default_xml
    client.use_dstu2
    reply = client.fetch_patient_record('example-patient')
    assert_equal :dstu2, reply.fhir_version
    assert_equal 'application/xml+fhir', reply.request[:headers]['Accept']
    assert reply.resource.is_a?(FHIR::DSTU2::Bundle)
    assert reply.resource.entry.last.resource.is_a?(FHIR::DSTU2::Patient)
  end

  def test_stu3_patient_record
    bundle = FHIR::Bundle.new({'id': 'foo'})
    bundle.entry << FHIR::Bundle::Entry.new
    bundle.entry.last.resource = FHIR::Patient.new({'id': 'example-patient'})
    stub_request(:get, 'http://stu3/Patient/example-patient/$everything').to_return(body: bundle.to_xml)
    client = FHIR::Client.new('stu3')
    client.default_xml
    reply = client.fetch_patient_record('example-patient')
    assert_equal :stu3, reply.fhir_version
    assert_equal 'application/fhir+xml', reply.request[:headers]['Accept']
    assert reply.resource.is_a?(FHIR::Bundle)
    assert reply.resource.entry.last.resource.is_a?(FHIR::Patient)
  end

  def test_dstu2_encounter_record
    bundle = FHIR::DSTU2::Bundle.new({'id': 'foo'})
    bundle.entry << FHIR::DSTU2::Bundle::Entry.new
    bundle.entry.last.resource = FHIR::DSTU2::Encounter.new({'id': 'example-encounter'})
    stub_request(:get, 'http://dstu2/Encounter/example-encounter/$everything').to_return(body: bundle.to_xml)
    client = FHIR::Client.new('dstu2')
    client.default_xml
    client.use_dstu2
    reply = client.fetch_encounter_record('example-encounter')
    assert_equal :dstu2, reply.fhir_version
    assert_equal 'application/xml+fhir', reply.request[:headers]['Accept']
    assert reply.resource.is_a?(FHIR::DSTU2::Bundle)
    assert reply.resource.entry.last.resource.is_a?(FHIR::DSTU2::Encounter)
  end

  def test_stu3_encounter_record
    bundle = FHIR::Bundle.new({'id': 'foo'})
    bundle.entry << FHIR::Bundle::Entry.new
    bundle.entry.last.resource = FHIR::Encounter.new({'id': 'example-encounter'})
    stub_request(:get, 'http://stu3/Encounter/example-encounter/$everything').to_return(body: bundle.to_xml)
    client = FHIR::Client.new('stu3')
    client.default_xml
    reply = client.fetch_encounter_record('example-encounter')
    assert_equal :stu3, reply.fhir_version
    assert_equal 'application/fhir+xml', reply.request[:headers]['Accept']
    assert reply.resource.is_a?(FHIR::Bundle)
    assert reply.resource.entry.last.resource.is_a?(FHIR::Encounter)
  end

  def test_dstu2_terminology_valueset_lookup
    stub_request(:post, /dstu2/).to_return(body: FHIR::DSTU2::Parameters.new({'id': 'results'}).to_xml)
    client = FHIR::Client.new('dstu2')
    client.default_xml
    client.use_dstu2
    options = {
      :operation => {
        :method => :get,
        :parameters => {
          'code' => { type: 'Code', value: 'chol-mmol' },
          'system' => { type: 'Uri', value: 'http://hl7.org/fhir/CodeSystem/example-crucible' }
        }
      }
    }
    reply = client.code_system_lookup(options)
    assert_equal :dstu2, reply.fhir_version
    assert_equal 'application/xml+fhir', reply.request[:headers]['Accept']
    assert reply.resource.is_a?(FHIR::DSTU2::Parameters)
  end

  def test_stu3_terminology_code_system_lookup
    stub_request(:post, /stu3/).to_return(body: FHIR::Parameters.new({'id': 'results'}).to_xml)
    client = FHIR::Client.new('stu3')
    client.default_xml
    options = {
      :operation => {
        :method => :get,
        :parameters => {
          'code' => { type: 'Code', value: 'chol-mmol' },
          'system' => { type: 'Uri', value: 'http://hl7.org/fhir/CodeSystem/example-crucible' }
        }
      }
    }
    reply = client.code_system_lookup(options)
    assert_equal :stu3, reply.fhir_version
    assert_equal 'application/fhir+xml', reply.request[:headers]['Accept']
    assert reply.resource.is_a?(FHIR::Parameters)
  end

end
