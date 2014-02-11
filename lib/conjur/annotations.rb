module Conjur
  # An Annotations instance acts like a Hash: you can fetch an annotation
  # with '[]' and update with '[]=', 'each' it, and 'merge!' to do bulk updates
  # (although merge! is not more efficient than setting each pair with '[]=').
  class Annotations
    # @api private
    def initialize resource
      @resource = resource
    end
    
    # Get the value of the annotation with the given name
    # @param [String,Symbol] name the annotation name, indifferent to whether it's
    # a String or Symbol.
    def [] name
      annotations_hash[name.to_sym]
    end
    
    # Set an annotation value
    # @param [String, Symbol] name the annotation name
    # @param [String] value the annotation value
    def []= name, value
      update_annotation name, value
      value
    end
    
    # Enumerate all annotations, yielding key,value pairs.
    # @return [Conjur::Annotations] self
    def each &blk
      annotations_hash.each &blk
      self
    end

    # Set annotations from key,value pairs in +hash+
    # @param [#each] hash
    # @return [Conjur::Annotations] self
    def merge! hash
      hash.each{|k,v| self[k] = v }
      self
    end
    
    # Return a proper hash containing a +copy+ of ourself.  Note that
    # updates to this hash have no effect on the actual annotations.
    # @return [Hash]
    def to_h
      annotations_hash.dup
    end
    
    def to_s
      annotations_hash.to_s
    end
    
    def inspect
      "<Annotations for #{@resource.resourceid}: #{to_s}>"
    end
    
    protected
    
    def update_annotation name, value
      @annotations_hash = nil
      path = [@resource.account,'annotations', @resource.kind, @resource.identifier].join '/'
      RestClient::Resource.new(Conjur::Authz::API.host, @resource.options)[path].put name: name, value: value
    end
    
    def annotations_hash
      @annotations_hash ||= fetch_annotations
    end
    
    def fetch_annotations
      {}.tap do |hash|
        JSON.parse(@resource.get)['annotations'].each do |annotation|
          hash[annotation['kind'].to_sym] = annotation['value']
        end
      end
    end
  end
end