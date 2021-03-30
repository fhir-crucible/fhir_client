require_relative '../../test_helper'

class ClientInterfaceSearchTest < Test::Unit::TestCase
  def setup
    @client = FHIR::Client.new("http://search-test")
  end
  def empty_search_response
    {
      headers: {
        'Content-Type': 'application/fhir+json'
      },
      body: { resourceType: 'Bundle' }.to_json
    }
  end

  def test_url_encoding_only_happens_once
    stub_request(:get, /search-test/).to_return(empty_search_response)
    reply = @client.search(
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
    assert_equal 'http://search-test/Appointment?date=%3E2016-01-01&patient=test',
                 reply.request[:url]
  end

  def test_get_search
    search_response = stub_request(:get, 'http://search-test/Patient?address=123%20Sesame%20Street&given=name').
      to_return(empty_search_response)

    reply = @client.search(
      FHIR::Patient,
      {
        search: {
          parameters: {
            given: 'name',
            address: '123 Sesame Street'
          }
        }
      }
    )
    assert_requested(search_response)
  end
  def test_post_search
    search_body = {
            given: 'name',
            address: '123 Sesame Street'
          }

    # Stub this request in a slightly more difficult manner to completely ensure that requests
    # contain encoded bodies and there isn't magic obscuring the fact that we are not.
    search_response = stub_request(:post, 'http://search-test/Patient/_search').
      with do |request|
        ['address=123+Sesame+Street&given=name', 'given=name&address=123+Sesame+Street'].include?(request.body) &&
        request.headers['Content-Type'] == 'application/x-www-form-urlencoded'
      end.to_return(empty_search_response)

    reply = @client.search(
      FHIR::Patient,
      {
        search: {
          body: search_body
        }
      }
    )
    assert_requested(search_response)
  end

  def test_post_search_no_body
    search_response = stub_request(:post, 'http://search-test/Patient/_search?address=123%20Sesame%20Street&given=name').
      with(headers: { 'Content-Type' => 'application/x-www-form-urlencoded' }).
      to_return(empty_search_response)

    reply = @client.search(
      FHIR::Patient,
      {
        search: {
          parameters: {
            given: 'name',
            address: '123 Sesame Street'
          },
          flag: true
        }
      }
    )
    assert_requested(search_response)
  end

  def test_post_search_body_and_params
    search_response = stub_request(:post, 'http://search-test/Patient/_search?address=123%20Sesame%20Street').
      with(body: {given: 'name'}, headers: {"Content-Type" => 'application/x-www-form-urlencoded'}).
      to_return(empty_search_response)

    reply = @client.search(
      FHIR::Patient,
      {
        search: {
          body: {
            given: 'name'
          },
          parameters: {
            address: '123 Sesame Street'
          }
        }
      }
    )
    assert_requested(search_response)
  end

  # It does not appear that this is still in the specification (if it ever was)
  # Investigate removing.  Keeping test until code is removed.
  def test_get_search_existing
    search_response = stub_request(:get, 'http://search-test/Patient/1?address=123%20Sesame%20Street&given=name').
      to_return(empty_search_response)

    reply = @client.search_existing(
      FHIR::Patient, 1,
      {
        search: {
          parameters: {
            given: 'name',
            address: '123 Sesame Street'
          }
        }
      }
    )
    assert_requested(search_response)
  end

  def test_get_search_all
    search_response = stub_request(:get, 'http://search-test/?address=123%20Sesame%20Street&given=name').
      to_return(empty_search_response)

    reply = @client.search_all(
      {
        search: {
          parameters: {
            given: 'name',
            address: '123 Sesame Street'
          }
        }
      }
    )
    assert_requested(search_response)
  end

end
