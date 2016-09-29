module FHIR
  module Sections
    module Tags
      #
      # Get a list of all tags on server
      #
      # GET [base]/_tags
      #
      # public List<AtomCategory> getAllTags();

      #
      # Get a list of all tags used for the nominated resource type
      #
      # GET [base]/[type]/_tags
      #
      # public <T extends Resource> List<AtomCategory> getAllTagsForResourceType(Class<T> resourceClass);

      #
      # Get a list of all tags affixed to the nominated resource. This duplicates the HTTP header entries
      #
      # GET [base]/[type]/[id]/_tags
      #
      # public <T extends Resource> List<AtomCategory> getTagsForResource(Class<T> resource, String id);

      #
      # Get a list of all tags affixed to the nominated version of the resource. This duplicates the HTTP header entries
      #
      # GET [base]/[type]/[id]/_history/[vid]/_tags
      #
      # public <T extends Resource> List<AtomCategory> getTagsForResourceVersion(Class<T> resource, String id, String versionId);

      #
      # Remove all tags in the provided list from the list of tags for the nominated resource
      #
      # DELETE [base]/[type]/[id]/_tags
      #
      # //public <T extends Resource> boolean deleteTagsForResource(Class<T> resourceClass, String id);

      #
      # Remove tags in the provided list from the list of tags for the nominated version of the resource
      #
      # DELETE [base]/[type]/[id]/_history/[vid]/_tags
      #
      # public <T extends Resource> List<AtomCategory> deleteTags(List<AtomCategory> tags, Class<T> resourceClass, String id, String version);

      #
      # Affix tags in the list to the nominated resource
      #
      # POST [base]/[type]/[id]/_tags
      # @return
      #
      # public <T extends Resource> List<AtomCategory> createTags(List<AtomCategory> tags, Class<T> resourceClass, String id);

      #
      # Affix tags in the list to the nominated version of the resource
      #
      # POST [base]/[type]/[id]/_history/[vid]/_tags
      #
      # @return
      #
      # public <T extends Resource> List<AtomCategory> createTags(List<AtomCategory> tags, Class<T> resourceClass, String id, String version);
    end
  end
end
