require_relative '../test_helper'

class BasicTest < Test::Unit::TestCase
  def client
    @client ||= FHIR::Client.new("feed-test")
  end

  def test_client_initialization
    assert !client.use_format_param, 'Using _format instead of [Accept] headers.'
  end

  def test_client_logs_without_response
    stub = stub_request(:get, /feed-test/).to_timeout
    # This used to provide a NoMethodError:
    # undefined method `request' for nil:NilClass
    # on the line which logs the request/response, because Response was nil
    assert_raise RestClient::RequestTimeout do
      client.read(FHIR::Patient, 123)
      assert_requested stub
    end
    client.use_oauth2_auth = true
    assert_raise RestClient::RequestTimeout do
      client.read(FHIR::Patient, 123)
      assert_requested stub
    end
  end
end
