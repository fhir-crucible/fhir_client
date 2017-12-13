module FHIR
  class Bundle
    def self_link
      link.select { |n| n.relation == 'self' }.first
    end

    def first_link
      link.select { |n| n.relation == 'first' }.first
    end

    def last_link
      link.select { |n| n.relation == 'last' }.first
    end

    def next_link
      link.select { |n| n.relation == 'next' }.first
    end

    def previous_link
      link.select { |n| n.relation == 'previous' || n.relation == 'prev' }.first
    end

    def get_by_id(id)
      entry.each do |item|
        return item.resource if item.id == id || item.resource.id == id
      end
      nil
    end

    def each(&block)
      iterator = @entry.map(&:resource).each(&block)
      if next_bundle
        next_iterator = next_bundle.each(&block)
        Enumerator.new do |y|
          iterator.each { |r| y << r }
          next_iterator.each { |r| y << r }
        end
      else
        iterator
      end
    end

    def next_bundle
      return nil unless client && next_link.try(:url)
      @next_bundle ||= client.parse_reply(self.class, client.default_format, client.raw_read_url(next_link.url))
    end
  end
end
