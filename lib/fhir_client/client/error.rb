module FHIR
  class Client
    class Error
      class NotImplemented < StandardError ; end
      # Create an exception for each HTTP code
      HTTP_CODE = {}
      
      Net::HTTPResponse::CODE_TO_OBJ.transform_values{|v| v.to_s.split('::').last}.each do |code, name|
        error_class = Class.new(StandardError)
        const_set name, error_class
        HTTP_CODE[code] = const_get(name)
      end
    end
  end
end
