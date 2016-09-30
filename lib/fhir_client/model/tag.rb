module FHIR
  class Tag
    # Each Tag is part of an HTTP header named "Category" with three parts: term, scheme, and label.
    # Each Tag can be in an individual "Category" header, or they can all be concatentated (with comma
    # separation) inside a single "Category" header.

    # Term is a URI:
    #   General tags:
    #     Bundle / FHIR Documents: "http://hl7.org/fhir/tag/document"
    #     Bundle / FHIR Messages:  "http://hl7.org/fhir/tag/message"
    #   Profile tags: URL that references a profile resource.
    attr_accessor :term

    # Scheme is a URI:
    #   "http://hl7.org/fhir/tag"           A general tag
    #   "http://hl7.org/fhir/tag/profile"   A profile tag - a claim that the Resource conforms to the profile identified in the term
    #   "http://hl7.org/fhir/tag/security"  A security label
    attr_accessor :scheme

    # Label is an OPTIONAL human-readable label for the tag for use when displaying in end-user applications
    attr_accessor :label

    def to_header
      s = "#{term}; scheme=#{scheme}"
      s += "; label=#{label}" unless label.nil?
      s
    end

    # Parses a string named "header" and returns a Tag object.
    def self.parse_tag(header)
      h = FHIR::Tag.new
      regex = /\s*;\s*/
      tokens = header.strip.split(regex)
      h.term = tokens.shift
      tokens.each do |token|
        if !token.strip.index('scheme').nil?
          token.strip =~ %r{(?<=scheme)(\s*)=(\s*)([\".:_\-\/\w]+)}
          h.scheme = Regexp.last_match(3)
        elsif !token.strip.index('label').nil?
          token.strip =~ %r{(?<=label)(\s*)=(\s*)([\".:_\-\/\w\s]+)}
          h.label = Regexp.last_match(3)
        end
      end
      h
    end

    # Parses a string named "header" and returns an Array of Tag objects.
    def self.parse_tags(header)
      tags = []
      regex = /\s*,\s*/
      tokens = header.strip.split(regex)
      tokens.each { |token| tags << FHIR::Tag.parse_tag(token) }
      tags
    end
  end
end
