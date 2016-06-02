module FHIR
  class Bundle
    include Enumerable

    def self_link
      link.select {|n| n.relation == 'self'}.first
    end

    def first_link
      link.select {|n| n.relation == 'first'}.first
    end

    def last_link
      link.select {|n| n.relation == 'last'}.first
    end

    def next_link
      link.select {|n| n.relation == 'next'}.first
    end

    def previous_link
      link.select {|n| n.relation == 'previous' || n.relation == 'prev'}.first
    end

    def get_by_id(id)
      entry.each do |item|
        return item.resource if item.id == id || item.resource.id == id
      end
      nil
    end

    def each(&block)
      iteration = @entry.map(&:resource).each(&block)
      iteration += next_bundle.each(&block) if next_bundle
      iteration
    end

    def next_bundle
      # TODO: test this
      return nil unless client && next_link.try(:url)
      @next_bundle ||= client.parse_reply(client.raw_read_url(next_link.url))
    end
  end
end

