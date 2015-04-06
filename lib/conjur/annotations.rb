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

require 'forwardable'

module Conjur
  # Conjur allows {http://developer.conjur.net/reference/services/authorization/resource Resource}
  #   instances to be {http://developer.conjur.net/reference/services/authorization/resource/annotate.html annotated}
  #   with arbitrary key-value data.  This data is generally for "user consumption", and it *is not* governed
  #   by any particular schema or constraints.  Your applications can define their own schema for annotations they
  #   use.  If you do so, we recommend prefixing your annotations, for example, `'myapp:Name'`, in order to avoid
  #   conflict with annotations used, for example, by the Conjur  UI.
  #
  # An Annotations instance acts like a Hash: you can fetch an annotation
  #   with {#[]} and update with {#[]=}, {#each} it, and {#merge!} to do bulk updates.
  #
  class Annotations
    include Enumerable

    # Create an `Annotations` instance for the given {Conjur::Resource}.
    #
    # Note that you will generally use the {Conjur::Resource#annotations} method to get
    # the `Annotations` for a {Conjur::Resource}.
    #
    # @param resource [Conjur::Resource]
    #
    def initialize resource
      @resource = resource
    end
    
    # Get the value of the annotation with the given name
    # @param [String,Symbol] name the annotation name, indifferent to whether it's
    # a String or Symbol.
    def [] name
      annotations_hash[name.to_sym]
    end
    
    # Set an annotation value.  This will perform an api call to set the annotation
    #   on the server.
    #
    # @param [String, Symbol] name the annotation name
    # @param [String] value the annotation value
    #
    # @return [String] the new annotation value
    def []= name, value
      update_annotation name.to_sym, value
      value
    end
    
    # Enumerate all annotations, yielding key,value pairs.
    # @return [Conjur::Annotations] self
    def each &blk
      annotations_hash.each &blk
      self
    end

    # Return a *copy* of the annotation values
    #
    # @example Changing values has no effectannotations_hash
    #   resource.annotations.values ["Some Value"]
    #   resource.annotations.values.each do |v|
    #     v << "HI"
    #   end
    #   resource.annotations.values # => ["Some Value"]
    #
    #    # Notice that this is different from ordinary Hash behavior
    #    h = {"Some Key" => "Some Value"}
    #    h.values.each do |v|
    #       v << "HI"
    #    end
    #    h.values # "Some ValueHI"
    #
    # @example Show the values of a resources annotations
    #   resource.annotations # => {'Name' => 'The Best Resource EVAR',
    #                        #  'Story' => 'The Coolest!' }
    #   resource.annotations.values # => ['The Best Resource EVAR', 'The Coolest!']
    #
    # @return [Array<String>] the annotation values
    def values
      annotations_hash.values.map(&:dup)
    end

    # Return the annotation names.
    #
    # This has exactly the same behavior as {Hash#keys}, in that the
    # returned keys are immutable, and modifications to the array have no
    # effect.
    #
    # @return [Array<String, Symbol>] the annotation names
    def keys
      annotations_hash.keys
    end
    alias names keys

    def to_a
      to_h.to_a
    end


    # Set annotations from key,value pairs in `hash`.
    #
    # @note this is currently no more efficient than setting each
    #   annotation with {#[]=}.
    #
    # @param [Hash, #each] hash
    # @return [Conjur::Annotations] self
    def merge! hash
      hash.each do |k, v|
        self[k] = v unless self[k] == v
      end
      self
    end
    
    # Return a proper hash containing a **copy** of the annotations.  Note that
    # updates to this hash have no effect on the actual annotations.
    #
    # @return [Hash]
    def to_h
      annotations_hash.dup
    end

    # Return the annotations hash as a string.  This method simply delegates to
    # `Hash#to_s`.
    #
    # @return [String]
    def to_s
      annotations_hash.to_s
    end

    # Return an informative representation of the annotations, including
    # the resource to which they're attached.  Suitable for debugging.
    #
    # @return [String]
    def inspect
      "<Annotations for #{@resource.resourceid}: #{to_s}>"
    end
    
    protected
    #@api private
    # Update an annotation on the server.
    # @param name [String]
    # @param value [String, #to_s]
    # @return [void]
    def update_annotation name, value
      @resource.invalidate do
        @annotations_hash = nil
        path = [@resource.account,'annotations', @resource.kind, @resource.identifier].join '/'
        RestClient::Resource.new(Conjur::Authz::API.host, @resource.options)[path].put name: name, value: value
      end
    end
    # @api private
    # Our internal {Hash} of annotations.  Lazily loaded.
    def annotations_hash
      @annotations_hash ||= fetch_annotations
    end

    # @api private
    # Fetch the annotations from the server.
    def fetch_annotations
      {}.tap do |hash|
        @resource.attributes['annotations'].each do |annotation|
          hash[annotation['name'].to_sym] = annotation['value']
        end
      end
    end
  end
end