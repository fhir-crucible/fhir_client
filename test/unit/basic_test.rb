require_relative '../test_helper'

class BasicTest < Test::Unit::TestCase
  def client
    @client ||= FHIR::Client.new("feed-test")
  end

  def test_client_initialization
    assert !client.use_format_param, 'Using _format instead of [Accept] headers.'
  end

  def test_client_logs_without_response
    # This used to provide a NoMethodError:
    # undefined method `request' for nil:NilClass
    # on the line which logs the request/response, because Response was nil
    format_headers = { format: :json}
    stubbed_path = 'Patient/1234'
    [false, true].each do |use_auth|
      client.use_oauth2_auth = use_auth
      %i[get delete head].each do |method|
        stub = stub_request(method, /feed-test/).to_timeout
        assert_raise RestClient::RequestTimeout do
          client.send(method, stubbed_path, format_headers)
          assert_requested stub
        end
      end
      %i[post put patch].each do |method|
        stub = stub_request(method, /feed-test/).to_timeout
        assert_raise RestClient::RequestTimeout do
          client.send(method, stubbed_path, FHIR::Patient.new, format_headers)
          assert_requested stub
        end
      end
    end
  end
end
