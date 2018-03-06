require_relative '../../test_helper'

class ClientInterfaceHistoryTest < Test::Unit::TestCase
  def client
    @client ||= FHIR::Client.new('history-test')
  end

  def test_history_uses_default_json_dstu2
    stub_request(:get, /history-test/).to_return(body: '{"resourceType":"Bundle"}')

    temp = client
    temp.use_dstu2
    temp.default_json

    reply = temp.all_history
    assert_equal FHIR::Formats::ResourceFormat::RESOURCE_JSON_DSTU2, reply.request[:headers]['format']
  end

  def test_history_uses_default_xml_dstu2
    stub_request(:get, /history-test/).to_return(body: '{"resourceType":"Bundle"}')

    temp = client
    temp.use_dstu2
    temp.default_xml

    reply = temp.all_history
    assert_equal FHIR::Formats::ResourceFormat::RESOURCE_XML_DSTU2, reply.request[:headers]['format']
  end

  def test_history_uses_default_json_stu3
    stub_request(:get, /history-test/).to_return(body: '{"resourceType":"Bundle"}')

    temp = client
    temp.use_stu3
    temp.default_json

    reply = temp.all_history
    assert_equal FHIR::Formats::ResourceFormat::RESOURCE_JSON, reply.request[:headers]['format']
  end

  def test_history_uses_default_xml_stu3
    stub_request(:get, /history-test/).to_return(body: '{"resourceType":"Bundle"}')

    temp = client
    temp.use_stu3
    temp.default_xml

    reply = temp.all_history
    assert_equal FHIR::Formats::ResourceFormat::RESOURCE_XML, reply.request[:headers]['format']
  end

end
