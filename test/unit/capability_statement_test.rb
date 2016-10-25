require_relative '../test_helper'

class CapabilityStatementTest < Test::Unit::TestCase
  def client
    @client ||= FHIR::Client.new('capability-test')
  end

  def test_metadata_returns_conformance
    root = File.expand_path '..', File.dirname(File.absolute_path(__FILE__))
    conformance = File.read(File.join(root, 'fixtures', 'conformance-example.json'))
    stub_request(:get, /capability-test/).to_return(body: conformance)
    statement = client.conformance_statement
    assert statement.is_a?(FHIR::Conformance)
    statement = client.capability_statement
    assert statement.is_a?(FHIR::Conformance)
  end


  def test_metadata_returns_capability_statement
    root = File.expand_path '..', File.dirname(File.absolute_path(__FILE__))
    capabilitystatement = File.read(File.join(root, 'fixtures', 'capabilitystatement-example.json'))
    stub_request(:get, /capability-test/).to_return(body: capabilitystatement)
    statement = client.conformance_statement
    assert statement.is_a?(FHIR::CapabilityStatement)
    statement = client.capability_statement
    assert statement.is_a?(FHIR::CapabilityStatement)
  end

end
