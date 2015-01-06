module FHIR
  class Bundle


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

  end
end
