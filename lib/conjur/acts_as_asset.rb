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
  # A mixin used by Conjur asset classes such as {Conjur::User} and {Conjur::Group}.
  module ActsAsAsset
    include HasId
    include Exists
    include HasOwner
    include ActsAsResource
    include HasAttributes

    # Add an internal grant on this asset's resource.  This method allows you to grant permissions on all members of
    # a container asset (for example, all hosts in a layer) to the given role.  Currently this method
    # is only useful for `layer` assets, and corresponds to the
    # {http://developer.conjur.net/reference/services/directory/layer/hosts-permit.html `hosts permit`} CLI
    # command.  In particular, to permit `'update'` on all hosts in a layer, `role_name` should be
    # `'admin_host'`, and to permit `'execute'` it should be `'use_host'`.
    #
    # @example Allow group 'ops' to admin hosts in the 'dev/database' layer
    #   ops = api.create_group 'ops'
    #   dev_database = api.create_layer 'dev/database'
    #
    #   # Create and add a host to the databasees layer
    #   host = api.create_host 'ec2/i-123ab23f'
    #   dev_databases.add_host host
    #
    #   # Ops can't update the hosts
    #   host.resource.permitted? 'update', acting_as: 'conjur:group:ops'
    #   # => false
    #
    #   # Allow 'group:ops' to admin all hosts in the layer
    #   layer.add_member 'admin_host', ops
    #
    #   # Now 'group:ops' is allowed to `'update'` the role.`
    #   host.resource.permitted? 'update', acting_as: 'group:ops'
    #   # => true
    #
    # @param [String] role_name name of the internal role to grant (for layers, it must be `'use_host'` or `'admin_host'`)
    # @param [String, #roleid] member the role to receive the grant
    # @param [Hash] options Unused, included for backwards compatibility
    # @return [void]
    def add_member(role_name, member, options = {})
      owned_role(role_name).grant_to member, options
    end

    # Remove a grant created with {#add_member}.  When an internal grant has been created on this asset's resource
    # with {#add_member}, you can remove it with this method.
    #
    # @see #add_member
    # @param [String] role_name name of the internal grant role (for layers, it must be `'use_host'` or `'admin_host'`).
    # @param [String, #roleid] member the role to remove
    # @return [void]
    def remove_member(role_name, member)
      owned_role(role_name).revoke_from member
    end
    
    protected

    # Return the internal role for an add/remove member grant.
    #
    # @param [String] role_name the name of the internal role
    # @return [Conjur::Role] the internal role
    def owned_role(role_name)
      tokens = [ resource_kind, resource_id, role_name ]
      grant_role = [ core_conjur_account, '@', tokens.join('/') ].join(':')
      require 'conjur/role'
      Conjur::Role.new(Conjur::Authz::API.host, self.options)[Conjur::API.parse_role_id(grant_role).join('/')]
    end
  end
end