module FHIR
  module Sections
    module Operations

      # DSTU 2 Operations: http://hl7.org/implement/standards/FHIR-Develop/operations.html

      # Concept Translation	[base]/ConceptMap/$translate | [base]/ConceptMap/[id]/$translate

      # Closure Table Maintenance	[base]/$closure

      # Fetch Patient Record	[base]/Patient/$everything | [base]/Patient/[id]/$everything
      # http://hl7.org/implement/standards/FHIR-Develop/patient-operations.html#everything
      # Fetches resources for a given patient record, scoped by a start and end time, and returns a Bundle of results
      def fetch_patient_record(id=nil, startTime=nil, endTime=nil, method='GET', format=@default_format)
        fetch_record(id,startTime,endTime,method,FHIR::Patient,format)
      end

      def fetch_encounter_record(id=nil, method='GET', format=@default_format)
        fetch_record(id,nil,nil,method,FHIR::Encounter,format)
      end

      def fetch_record(id=nil, startTime=nil, endTime=nil, method='GET', klass=FHIR::Patient, format=@default_format)
        options = { resource: klass, format: format, operation: { name: :fetch_patient_record, method: method } }
        options.deep_merge!({id: id}) if !id.nil?
        options[:operation][:parameters] = {} if options[:operation][:parameters].nil?
        options[:operation][:parameters].merge!({start: { type: 'Date', value: startTime}}) if !startTime.nil?
        options[:operation][:parameters].merge!({end: { type: 'Date', value:endTime}}) if !endTime.nil?

        if options[:operation][:method]=='GET'
          reply = get resource_url(options), fhir_headers(options)
        else
          # create Parameters body
          body = nil
          if(options[:operation] && options[:operation][:parameters])
            p = FHIR::Parameters.new
            options[:operation][:parameters].each do |key,value|
              parameter = FHIR::Parameters::Parameter.new.from_hash(name: key.to_s)
              parameter.method("value#{value[:type]}=").call(value[:value])
              p.parameter << parameter
            end
            body = p.to_xml
          end
          reply = post resource_url(options), p, fhir_headers(options)
        end

        reply.resource = parse_reply(FHIR::Bundle, format, reply)
        reply.resource_class = options[:resource]
        reply
      end

      # Build Questionnaire	[base]/Profile/$questionnaire | [base]/Profile/[id]/$questionnaire

      # Populate Questionnaire	[base]/Questionnaire/$populate | [base]/Questionnaire/[id]/$populate

      # Value Set Expansion	[base]/ValueSet/$expand | [base]/ValueSet/[id]/$expand
      # http://hl7.org/implement/standards/FHIR-Develop/valueset-operations.html#expand
      # The definition of a value set is used to create a simple collection of codes suitable for use for data entry or validation.
      def value_set_expansion(params={}, format=@default_format)
        options = { resource: FHIR::ValueSet, operation: { name: :value_set_expansion } }
        options.deep_merge!(params)
        terminology_operation(options, format)
      end

      # Value Set based Validation	[base]/ValueSet/$validate | [base]/ValueSet/[id]/$validate
      # http://hl7.org/implement/standards/FHIR-Develop/valueset-operations.html#validate
      # Validate that a coded value is in the set of codes allowed by a value set.
      def value_set_code_validation(params={}, format=@default_format)
        options = { resource: FHIR::ValueSet,  operation: { name: :value_set_based_validation } }
        options.deep_merge!(params)
        terminology_operation(options, format)
      end

      # Concept Look Up [base]/CodeSystem/$lookup
      def code_system_lookup(params={}, format=@default_format)
        options = { resource: FHIR::CodeSystem, operation: { name: :code_system_lookup } }
        options.deep_merge!(params)
        terminology_operation(options, format)
      end

      #
      def concept_map_translate(params={}, format=@default_format)
        options = { resource: FHIR::ConceptMap, operation: { name: :concept_map_translate } }
        options.deep_merge!(params)
        terminology_operation(options, format)
      end

      def terminology_operation(params={}, format=@default_format)
        options = { format: format }
        # params = [id, code, system, version, display, coding, codeableConcept, date, abstract]
        options.deep_merge!(params)

        if options[:operation][:method]=='GET'
          reply = get resource_url(options), fhir_headers(options)
        else
          # create Parameters body
          body = nil
          if(options[:operation] && options[:operation][:parameters])
            p = FHIR::Parameters.new
            options[:operation][:parameters].each do |key,value|
              parameter = FHIR::Parameters::Parameter.new.from_hash(name: key.to_s)
              parameter.method("value#{value[:type]}=").call(value[:value])
              p.parameter << parameter
            end
            body = p.to_xml
          end
          reply = post resource_url(options), p, fhir_headers(options)
        end

        reply.resource = parse_reply(options[:resource], format, reply)
        reply.resource_class = options[:resource]
        reply
      end

      # Batch Mode Validation	[base]/ValueSet/$batch

    end
  end
end
