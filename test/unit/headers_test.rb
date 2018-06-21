require_relative '../test_helper'

class HeadersTest < Test::Unit::TestCase
  def client
    @client ||= FHIR::Client.new("headers-test")
  end

  def test_client_additional_headers
    client.additional_headers = { "X-API-VERSION" => "1" }

    headers = client.fhir_headers

    assert headers["X-API-VERSION"] == "1"
  end
end
