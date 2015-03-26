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

  # This module provides methods for things that have an associated {Conjur::Role}.
  #
  # All high level Conjur assets (groups and users, for example) are composed of both a role and a resource.  This allows
  # these assets to have permissions on other assets, and for other assets to have permission
  # on them.
  #
  # The {Conjur::ActsAsRole} module itself should be considered private, but it's methods are
  # public when added to a Conjur asset class.
  module ActsAsRole

    # The qualified identifier for the role associated with this asset.  A *qualified* identifier
    # prepends the asset's account and kind, for example, a {Conjur::User} with login `'bob'` in a
    # system with organizational account `'conjur'` would have a `roleid` of `'conjur:user:bob'`
    #
    # @return [String] the qualified role id
    def roleid
      [ core_conjur_account, role_kind, id ].join(':')
    end
    alias role_id roleid

    # The `kind` of a role.  This may be any value, but standard ones correspond to various high level
    # Conjur assets, for example, `'user'`, `'group'`, or `'variable'`.
    #
    # Note that this method derives the role kind from the asset's class name.
    #
    # @return [String] the role kind
    def role_kind
      self.class.name.split('::')[-1].underscore
    end

    # Get a {Conjur::Role} instance corresponding to the `role` associated with this asset.
    def role
      require 'conjur/role'
      Conjur::Role.new(Conjur::Authz::API.host, self.options)[Conjur::API.parse_role_id(self.roleid).join('/')]
    end

    # Permit the asset to perform `privilege` on `resource`.  You can also use this method to control whether the role
    # is able to grant the privilege on the resource to other roles by passing a `:grant_option` option.
    #
    # This method is primarily intended for use in the
    # {http://developer.conjur.net/reference/tools/utilities/policy-load.html Conjur Policy DSL},
    # and simply delegates to {Conjur::Resource#permit}.  For code clarity, you might consider using
    # that method instead.
    #
    # ### Permissions
    #
    # To call this method, you must *own* the resource, or have the privilege on it with grant option set to true.
    #
    # @api dsl
    # @param [String] privilege the privilege to allow this role to perform, e.g. `'execute'` or `'update'`
    # @param [Conjur::Resource, #resource_id, String] resource the resource to grant `privilege` on.
    # @param [Hash] options Options to pass through to RestClient::Resource#post
    # @option options [Boolean] :grant_option whether this role will be able to grant the privilege to other roles.
    # @return [void]
    def can(privilege, resource, options = {})
      require 'conjur/resource'
      Conjur::Resource.new(Conjur::Authz::API.host, self.options)[Conjur::API.parse_resource_id(resource).join('/')].permit privilege, self.roleid, options
    end

    # Deny the asset's role the ability to perform `privilege` on `resource`.  This operation is the inverse of {#can}.
    #
    # This method is primarily intended for use in the
    # {http://developer.conjur.net/reference/tools/utilities/policy-load.html Conjur Policy DSL},
    # and simply delegates to {Conjur::Resource#permit}.  For code clarity, you might consider using
    # that method instead.
    #
    # @see Conjur::Resource#deny
    #
    # @api dsl
    def cannot(privilege, resource, options = {})
      require 'conjur/resource'
      Conjur::Resource.new(Conjur::Authz::API.host, self.options)[Conjur::API.parse_resource_id(resource).join('/')].deny privilege, self.roleid
    end
  end
end