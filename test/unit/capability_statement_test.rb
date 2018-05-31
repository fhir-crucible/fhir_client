require_relative '../test_helper'

class CapabilityStatementTest < Test::Unit::TestCase
  def client
    @client ||= FHIR::Client.new('capability-test')
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


  def test_can_configure_oauth_from_capability_statement
    root = File.expand_path '..', File.dirname(File.absolute_path(__FILE__))
    capabilitystatement = File.read(File.join(root, 'fixtures', 'oauth_capability_statement.json'))
    stub_request(:get, /capability-test/).to_return(body: capabilitystatement)
    statement = client.conformance_statement
    assert statement.is_a?(FHIR::CapabilityStatement)
    statement = client.capability_statement
    assert statement.is_a?(FHIR::CapabilityStatement)
    # # should be able to get the options when the coding is not there and strict is false
    options = client.get_oauth2_metadata_from_conformance(false)
    assert_equal "https://authorize.smarthealthit.org/authorize", options[:authorize_url]
    assert_equal "https://authorize.smarthealthit.org/token", options[:token_url]
    # #should not be able to get the options if strict and the codeing is not there
    options = client.get_oauth2_metadata_from_conformance
    assert options.empty?

  end

  def test_can_configure_oauth_from_capability_statement_strict
    root = File.expand_path '..', File.dirname(File.absolute_path(__FILE__))
    capabilitystatement = File.read(File.join(root, 'fixtures', 'oauth_capability_statement_strict.json'))
    stub_request(:get, /capability-test/).to_return(body: capabilitystatement)
    statement = client.conformance_statement
    assert statement.is_a?(FHIR::CapabilityStatement)
    statement = client.capability_statement
    assert statement.is_a?(FHIR::CapabilityStatement)
    #should be able to get the options when strict and the codeing is there
    options = client.get_oauth2_metadata_from_conformance
    assert_equal "https://authorize.smarthealthit.org/authorize", options[:authorize_url]
    assert_equal "https://authorize.smarthealthit.org/token", options[:token_url]

  end

end
