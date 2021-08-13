require_relative '../test_helper'

class SetClientOnResourceTest < Test::Unit::TestCase
  def client
    @client ||= FHIR::Client.new('abc')
  end

  def test_r4
    condition = FHIR::Condition.new(
      resourceType: 'Condition',
      subject: {
        reference: 'Patient/123'
      }
    )
    client.set_client_on_resource(condition)

    assert_equal(client, condition.client)
    assert_equal(client, condition.subject.client)
  end

  def test_stu3
    condition = FHIR::STU3::Condition.new(
      resourceType: 'Condition',
      subject: {
        reference: 'Patient/123'
      }
    )
    client.set_client_on_resource(condition)

    assert_equal(client, condition.client)
    assert_equal(client, condition.subject.client)
  end

  def test_dstu2
    condition = FHIR::DSTU2::Condition.new(
      resourceType: 'Condition',
      patient: {
        reference: 'Patient/123'
      }
    )
    client.set_client_on_resource(condition)

    assert_equal(client, condition.client)
    assert_equal(client, condition.patient.client)
  end
end
