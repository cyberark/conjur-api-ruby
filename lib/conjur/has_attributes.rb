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
  # Many Conjur assets have key-value attributes.  Although these should generally be accessed via
  # methods on specific asset classes (for example, {Conjur::Resource#owner}), the are available as
  # a `Hash` on all types supporting attributes.
  module HasAttributes
    # Returns this objects {#attributes}.  This is primarily to support
    # simple JSON serialization of Conjur assets.
    #
    # @param options [Hash,nil] unused, kept for compatibility reasons
    # @see #attributes
    def to_json(options = {})
      attributes
    end

    # @api private
    # Set the attributes for this Resource.
    # @param [Hash] attributes new attributes for the object.
    # @return [Hash] the new attributes
    def attributes=(attributes); @attributes = attributes; end

    # Get the attributes for this asset.
    #
    # Although the `Hash` returned by this method is mutable, you should treat as immutable unless you know
    # exactly what you're doing.  Each asset's attributes are constrained by a server side schema, which means
    # that you will get an error if you violate the schema. and then try to save the asset.
    #
    #
    # @note this method will use a cached copy of the objects attributes instead of fetching them
    # with each call.  To ensure that the attributes are fresh, you can use the {#refresh} method
    #
    # @return [Hash] the asset's attributes.
    def attributes
      return @attributes if @attributes
      fetch
    end


    # Update this asset's attributes on the server.
    #
    #
    # @note If the objects attributes haven't been fetched (for example, by calling {#attributes}),
    #   this method is a no-op.
    #
    # Although you can manipulate an assets attributes and then call {#save}, the attributes are constrained
    # by a server side schema, and attempting to set an attribute that doesn't exist will result in
    # a 422 Unprocessable Entity error.
    #
    # If you want to set arbitrary metadata on an asset, you might consider using the {Conjur::Resource#tags}
    # method instead.
    #
    # @return [void]
    def save
      if @attributes
        self.put(attributes.to_json)
      end
    end
    
    # Reload this asset's attributes. This method can be used to guarantee a current view of the entity in the case
    # that it has been modified by an update method or by an external party.
    #
    # @note any changes to {#attributes} without a call to #save will be overwritten by this method.
    #
    # @example
    #   res = api.resources.firs
    #   res.attributes # => {  ... }
    #   res.attributes['hello'] = 'blah'
    #   res.refresh
    #   res.attributes['hello'] # => nil
    #
    #
    # @return [Hash] the asset's attributes.
    def refresh
      fetch
    end

    # Call a block that will perform actions that might change the asset's attributes.
    # No matter what happens in the block, this method ensures that the cached attributes
    # will be invalidated.
    #
    # @note this is mainly used internally, but included in the public api for completeness.
    #
    # @return [void]
    def invalidate(&block)
      yield
    ensure
      @attributes = nil
    end

    protected

    # @api private
    # Fetch the attributes, overwriting any current ones.
    def fetch
      @attributes = fetch_attributes
    end

    def fetch_attributes # :nodoc:
      JSON.parse(get.body)
    end
  end
end