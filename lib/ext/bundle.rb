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
      @entry.each(&block)
    end

    # TODO: upgrade client to easily get a bundle if given a link
    # def next
    #   return nil if next_link.nil?
    #   self.class.last_response = self.class.configuration.client.raw_read_url next_link.url
    #   self.class.last_response.resource
    # end

    # def previous
    #   return nil if previous_link.nil?
    #   self.class.last_response = self.class.configuration.client.raw_read_url previous_link.url
    #   self.class.last_response.resource
    # end
  end
end

