#
# Copyright (C) 2013 Conjur Inc
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
module Conjur
  # An Annotations instance acts like a Hash: you can fetch an annotation
  # with '[]' and update with '[]=', 'each' it, and 'merge!' to do bulk updates
  # (although merge! is not more efficient than setting each pair with '[]=').
  class Annotations
    include Enumerable
    
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
      @resource.invalidate do
        @annotations_hash = nil
        path = [@resource.account,'annotations', @resource.kind, @resource.identifier].join '/'
        RestClient::Resource.new(Conjur::Authz::API.host, @resource.options)[path].put name: name, value: value
      end
    end
    
    def annotations_hash
      @annotations_hash ||= fetch_annotations
    end
    
    def fetch_annotations
      {}.tap do |hash|
        @resource.attributes['annotations'].each do |annotation|
          hash[annotation['name'].to_sym] = annotation['value']
        end
      end
    end
  end
end