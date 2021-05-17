require_relative '../test_helper'

class BasicTest < Test::Unit::TestCase
  def client
    @client ||= FHIR::Client.new("http://basic-test.com/fhir/")
  end

  def test_client_initialization
    assert !client.use_format_param, 'Using _format instead of [Accept] headers.'
  end

  def test_set_basic_auth_auth
    client.set_basic_auth('client', 'secret')

    assert client.use_oauth2_auth == false
    assert client.use_basic_auth == true
    assert client.security_headers == {"Authorization"=>"Basic Y2xpZW50OnNlY3JldA==\n"}
    assert RestClient == client.client
  end

  def test_bearer_token_auth
    client.set_bearer_token('secret_token')

    assert client.use_oauth2_auth == false
    assert client.use_basic_auth == true
    assert client.security_headers == {"Authorization"=>"Bearer secret_token"}
    assert RestClient == client.client
  end

  def test_oauth2_token_auth
    stub_request(:post, /token_path/).to_return(status: 200, body: '{"access_token" : "valid_token"}', headers: {'Content-Type' => 'application/json'})

    client.set_oauth2_auth("client", "secret", "authorize_path", "token_path")

    assert client.use_oauth2_auth == true
    assert client.use_basic_auth == false
    assert client.security_headers == {}
    assert OAuth2::AccessToken === client.client

    assert client.client.client.site == "http://basic-test.com/fhir/"
  end

  def test_oauth2_token_auth_custom
    stub_request(:post, /token_path/).to_return(status: 200, body: '{"access_token" : "valid_token"}', headers: {'Content-Type' => 'application/json'})

    client.set_oauth2_auth("client", "secret", "authorize_path", "token_path", "http://custom-test.com/fhir/")

    assert client.use_oauth2_auth == true
    assert client.use_basic_auth == false
    assert client.security_headers == {}
    assert OAuth2::AccessToken === client.client

    assert client.client.client.site == "http://custom-test.com/fhir/"
  end

  def test_client_logs_without_response
    # This used to provide a NoMethodError:
    # undefined method `request' for nil:NilClass
    # on the line which logs the request/response, because Response was nil
    format_headers = { format: :json }
    stubbed_path = 'Patient/1234'
    [false,true].each do |use_oauth|
      if use_oauth
        stub_request(:post, /token_path/).to_return(status: 200, body: '{"access_token" : "valid_token"}', headers: {'Content-Type' => 'application/json'})
        client.set_oauth2_auth("client", "secret", "authorize_path", "token_path")
        timeouts = [Faraday::ConnectionFailed]
        raises   =  Faraday::ConnectionFailed
      else
        client.set_basic_auth('client', 'secret')
        timeouts = [RestClient::RequestTimeout, RestClient::Exceptions::OpenTimeout]
        raises   =  SocketError
      end

      %i[get delete head].each do |method|
        stub = stub_request(method, /basic-test/).to_timeout
        assert_raise(*timeouts) do
          client.send(method, stubbed_path, format_headers)
          assert_requested stub
        end
        stub = stub_request(method, /basic-test/).to_raise(SocketError)
        assert_raise(raises) do
          client.send(method, stubbed_path, format_headers)
          assert_requested raises
        end
      end
      %i[post put patch].each do |method|
        stub = stub_request(method, /basic-test/).to_timeout
        assert_raise(*timeouts) do
          client.send(method, stubbed_path, FHIR::Patient.new, format_headers)
          assert_requested stub
        end
        stub = stub_request(method, /basic-test/).to_raise(SocketError)
        assert_raise(raises) do
          client.send(method, stubbed_path, FHIR::Patient.new, format_headers)
          assert_requested raises
        end
      end
    end
  end
end
