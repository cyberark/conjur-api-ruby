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

require 'active_support/dependencies/autoload'
require 'active_support/core_ext'

module Conjur

  # This module is included in asset classes that have an associated resource.
  module ActsAsResource
    # Return the {Conjur::Resource} associated with this asset.
    #
    # @return [Conjur::Resource] the resource associated with this asset
    def resource
      require 'conjur/resource'
      # NOTE: should we use specific class to build sub-url below?
      Conjur::Resource.new(Conjur::Authz::API.host, self.options)[[ core_conjur_account, 'resources', path_escape(resource_kind), path_escape(resource_id) ].join('/')]
    end

    # Return the *qualified* id of the resource associated with this asset.
    #
    # @return [String] the qualified id of the resource associated with this asset.
    def resourceid
      [ core_conjur_account, resource_kind, resource_id ].join(':')
    end

    # The kind of resource underlying the asset.  The kind is the second token in
    # a Conjur id like `"account:kind:id"`.
    #
    # @see Conjur:Resource#kind
    # @return [String] the resource kind for the underlying resource
    def resource_kind
      self.class.name.split("::")[-1].underscore.split('/').join('-')
    end

    # @api private
    #
    # Confusingly, this method returns the *unqualified* resource id, as opposed to the *qualified*
    # resource id returned by {#resourceid}.
    #
    # @return [String] the *unqualified* resource id.
    def resource_id
      id
    end

    # @api private
    # Delete a resource
    # This doesn't typically work ;-)
    # @return [void]
    def delete
      resource.delete
      super
    end

    # Permit `role` to perform `privilege` on this resource.  A
    # {http://developer.conjur.net/reference/services/authorization/permission.html permission} represents an ability
    # to perform certain (application defined) actions on this resource.
    #
    # This method is equivalent to calling `resource.permit`.
    #
    # @example Allow a group and its members to get the value of a Conjur variable
    #   group = api.group 'some-project/developers'
    #   variable = api.variable 'some-project/development/postgres-uri'
    #   variable.permit 'execute', group
    #
    # @see Conjur::Resource#permit
    # @param [String] privilege the privilege to grant
    # @param [String, #roleid] role the role to which the privilege is granted
    # @param options [Hash, nil] options to pass through to `RestClient::Resource#post`
    # @return [void]
    # @raise [RestClient::Forbidden] if you don't have permission to perform this operation.
    def permit(privilege, role, options = {})
      resource.permit privilege, role, options
    end


    # Deny `role` permission to perform actions corresponding to `privilege` on the underlying resource.
    #
    # @see Conjur::Resource#deny
    # @param privilege [String, #each] A permission name or an `Enumerable` of permissions to deny.  In the
    #   later, all permissions will be denied.
    # @param role [String, :roleid] A full role id or a role-ish object whose permissions we will deny.
    #
    # @return [void]
    def deny(privilege, role)
      resource.deny privilege, role
    end
  end
end
