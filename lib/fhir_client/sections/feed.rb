module FHIR
  module Sections
    module Feed
      FORWARD = :next_link
      BACKWARD = :previous_link
      FIRST = :first_link
      LAST = :last_link

      def next_page(current, page = FORWARD)
        bundle = current.resource
        link = bundle.method(page).call
        return nil unless link
        reply = get strip_base(link.url), fhir_headers(format: @default_format)
        reply.resource = parse_reply(current.resource_class, @default_format, reply)
        reply.resource_class = current.resource_class
        reply
      end
    end
  end
end
