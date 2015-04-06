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
  # This module provides methods for determining Conjur id components from an asset's
  # REST URL.
  module PathBased
    # Return the Conjur {LINK organizational account} for this role or resource.  The `account`
    # is the first token in a fully qualified Conjur id, like `"account:kind:identifier"`
    #
    # @example
    #   role = api.role 'foo:bar:baz'
    #   role.account # => 'foo'
    #
    # @return [String] the Conjur organizational account
    def account
      match_path(0..0)
    end

    # Return the *kind* for this role or resource.  The kind partitions the space of roles and resources, generally
    # according to their purpose (for example, roles representing users have kind `'user'`).  The `kind` of a role or
    # resource is the second token of a fully qualified Conjur id, like `"account:kind:identifier"`.
    #
    # @example Get the kind of a role
    #   role = api.host('postgres-1').role
    #   role.kind # => 'host'
    #
    # @example Get the kind of a resource
    #   res  = api.host('postgres-1').resource
    #   res.kind # => 'host'
    #
    # @return [String] the kind of the role or resource
    def kind
      match_path(2..2)
    end
    
    protected

    # @api private
    #
    # Returns the path parts in the given range.
    #
    # @example
    #   self.url # => "https://10.0.3.100/api/authz/foo/roles/bar/baz"
    #   self.match_path 0..2 # => "foo/roles/bar"
    #   self.match_path 2..-1 # => "bar/baz"
    #
    # @param [Range] the range of parts
    # @return [String] the parts joined by `'/'`
    def match_path(range)
      tokens[range].map{|t| URI.unescape(t)}.join('/')
    end

    # @api private
    #
    # Returns the components of this asset's path starting with the first component
    # that isn't part of the authz service url.
    #
    # @example
    #   self.url # => "https://10.0.3.100/api/authz/foo/roles/bar/baz"
    #   self.tokens # => ["foo", "roles", "bar", "baz"]
    #
    # @return [Array<String>] the path components
    def tokens
      self.url[RestClient::Resource.new(Conjur::Authz::API.host)[''].url.length..-1].split('/')
    end
  end
end