require_relative '../../test_helper'

class ClientInterfaceSearchTest < Test::Unit::TestCase
  def client
    @client ||= FHIR::Client.new("feed-test")
  end

  def test_url_encoding_only_happens_once
    stub_request(:get, /feed-test/)
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
    assert_equal 'feed-test/Appointment?date=%3E2016-01-01&patient=test',
                 reply.request[:url]
  end
end
