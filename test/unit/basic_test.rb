require_relative '../test_helper'

class BasicTest < Test::Unit::TestCase

  def test_client_initialization
    client = FHIR::Client.new('TESTING_ENDPOINT')
    assert !client.use_format_param, 'Using _format instead of [Accept] headers.'
  end

end
