require_relative '../../test_helper'

class ClientInterfaceSearchTest < Test::Unit::TestCase
  def client
    @client ||= FHIR::Client.new("search-test")
  end

  def test_url_encoding_only_happens_once
    stub_request(:get, /search-test/).to_return(body: '{"resourceType":"Bundle"}')
    reply = client.search(
      FHIR::Appointment,
      {
        search: {
          parameters: {
            'patient' => 'test',
            'date' => '>2016-01-01'
          }
        }
      }
    )
    assert_equal 'search-test/Appointment?date=%3E2016-01-01&patient=test',
                 reply.request[:url]
  end

  def test_url_encoded_form
    stub_request(:post, /search-test/).to_return(body: '{"resourceType":"Bundle"}')
    headers = client.fhir_headers(content_type: 'application/x-www-form-urlencoded')
    payload = {test: "test-body"}
    reply = client.send(:post, '/search-test', payload, headers)

    assert_equal 'test=test-body', reply.request[:payload]
  end
end
