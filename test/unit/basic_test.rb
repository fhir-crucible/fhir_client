require_relative '../test_helper'

class BasicTest < Test::Unit::TestCase

  TESTING_ENDPOINT = 'http://fhir.healthintersections.com.au/open'

  def test_client_initialization
    client = FHIR::Client.new(TESTING_ENDPOINT)
    assert !client.use_format_param, "Using _format instead of [Accept] headers."
  end

  def test_conformance
    client = FHIR::Client.new(TESTING_ENDPOINT)
    assert !client.conformanceStatement.blank?, "Unable to retrieve conformance statement."
  end

end
