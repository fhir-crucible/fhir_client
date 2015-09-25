module FHIR
  module Sections
    module Feed

      FORWARD = :next_link
      BACKWARD = :previous_link
      FIRST = :first_link
      LAST = :last_link

      def next_page(current, page=FORWARD)
        bundle = current.resource
        link = bundle.method(page).call
        return nil unless link
        reply = get strip_base(link.url), fhir_headers
        reply.resource = parse_reply(current.resource_class, @default_format_bundle, reply)
        reply.resource_class = current.resource_class
        reply
      end


    end
  end
end
