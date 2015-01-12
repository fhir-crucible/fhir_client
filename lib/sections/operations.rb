module FHIR
  module Sections
    module Operations

      # DSTU 2 Operations: http://hl7.org/implement/standards/FHIR-Develop/operations.html

      # Concept Translation	[base]/ConceptMap/$translate | [base]/ConceptMap/[id]/$translate

      # Closure Table Maintenance	[base]/$closure

      # Fetch Patient Record	[base]/Patient/$everything | [base]/Patient/[id]/$everything
      # http://hl7.org/implement/standards/FHIR-Develop/patient-operations.html#everything
      # Fetches resources for a given patient record, scoped by a start and end time, and returns a Bundle of results
      def fetch_patient_record(id=nil, startTime=nil, endTime=nil, format=FHIR::Formats::ResourceFormat::RESOURCE_XML)
        options = { resource: FHIR::Patient, format: format, operation: :fetch_patient_record }
        options.merge!({id: id}) if !id.nil?
        options.merge!({start: startTime}) if !startTime.nil?
        options.merge!({end: endTime}) if !endTime.nil?
        reply = get resource_url(options), fhir_headers(options)
        reply.resource = parse_reply(FHIR::Bundle, format, reply.body)
        reply.resource_class = options[:resource]
        reply
      end

      # Build Questionnaire	[base]/Profile/$questionnaire | [base]/Profile/[id]/$questionnaire

      # Populate Questionnaire	[base]/Questionnaire/$populate | [base]/Questionnaire/[id]/$populate

      # Value Set Expansion	[base]/ValueSet/$expand | [base]/ValueSet/[id]/$expand

      # Concept Look Up	[base]/ValueSet/$lookup

      # Value Set based Validation	[base]/ValueSet/$validate | [base]/ValueSet/[id]/$validate

      # Batch Mode Validation	[base]/ValueSet/$batch

    end
  end
end
