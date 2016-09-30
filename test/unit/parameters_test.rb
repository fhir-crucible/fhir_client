require_relative '../test_helper'

class ParametersTest < Test::Unit::TestCase
  # <?xml version="1.0" encoding="UTF-8"?>
  # <Parameters xmlns="http://hl7.org/fhir">
  #   <id value="example"/>
  #   <parameter>
  #     <name value="start"/>
  #     <valueDate value="2010-01-01"/>
  #   </parameter>
  #   <parameter>
  #     <name value="end"/>
  #     <resource>
  #       <Binary>
  #         <contentType value="text/plain"/>
  #         <content value="VGhpcyBpcyBhIHRlc3QgZXhhbXBsZQ=="/>
  #       </Binary>
  #     </resource>
  #   </parameter>
  # </Parameters>
  def test_example_parameters_xml
    root = File.expand_path '..', File.dirname(File.absolute_path(__FILE__))
    xml = File.read(File.join(root, 'fixtures', 'parameters-example.xml'))
    parameters = FHIR::Xml.from_xml(xml)
    check_params(parameters)
   end

  def test_example_parameters_json
    root = File.expand_path '..', File.dirname(File.absolute_path(__FILE__))
    json = File.read(File.join(root, 'fixtures', 'parameters-example.json'))
    parameters = FHIR::Json.from_json(json)
    check_params(parameters)
  end

  def check_params(parameters)
    message = 'Failed to parse example Parameters.'
    assert parameters.parameter.length == 2, message
    assert parameters.parameter[0].name == 'start', message
    assert parameters.parameter[0].valueDate == '2010-01-01', message
    assert parameters.parameter[1].name == 'end', message
    assert !parameters.parameter[1].resource.nil? && parameters.parameter[1].resource.class == FHIR::Binary, message
  end
end
