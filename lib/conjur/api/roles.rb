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
require 'conjur/role'
require 'conjur/graph'

module Conjur
  class API
    #@!group Authorization: Roles

    # Fetch a {Conjur::Graph} representing the relationships of a given role or roles.  Such graphs are transitive,
    # and follow the normal permissions for role visibility.
    #
    # @param [Array<Conjur::Role, String>, String, Conjur::Role] roles role or or array of roles
    #   roles whose relationships we're interested in
    # @param [Hash] options options for the request
    # @option opts [Boolean] :ancestors Whether to return ancestors of the given roles (true by default)
    # @option opts [Boolean] :descendants Whether to return descendants of the given roles (true by default)
    # @option opts [Conjur::Role, String] :as_role Only roles visible to this role will be included in the graph
    # @return [Conjur::Graph] An object representing the role memberships digraph
    def role_graph roles, options = {}
      roles = [roles] unless roles.kind_of? Array
      roles.map!{|r| normalize_roleid(r) }
      options[:as_role] = normalize_roleid(options[:as_role]) if options.include?(:as_role)
      options.reverse_merge! as_role: normalize_roleid(current_role), descendants: true, ancestors: true

      query = {from_role: options.delete(:as_role)}
        .merge(options.slice(:ancestors, :descendants))
        .merge(roles: roles).to_query
      Conjur::Graph.new RestClient::Resource.new(Conjur::Authz::API.host, credentials)["#{Conjur.account}/roles?#{query}"].get
    end

    # Create a {Conjur::Role} with the given id.
    #
    # ### Permissions
    # * All Conjur roles can create new roles.
    # * The creator role (either the current role or the role given by the `:acting_as` option)
    #   is made a member of the new role.  The new role is also made a member of itself.
    # * If you give an `:acting_as` option, you must be a (transitive) member of the `:acting_as`
    #   role.
    # * The new role is granted to the creator role with *admin option*: that is, the creator role
    #   is able to grant the created role to other roles.
    #
    # @example Basic role creation
    #   # Current role is 'user:jon', assume the organizational account is 'conjur'
    #    api.current_role # => 'conjur:user:jon'
    #
    #   # Create a Conjur actor to control the permissions of a chron job (rebuild_indices)
    #   role = api.create_role 'robot:rebuild_indices'
    #   role.role_id # => "conjur:robot:rebuild_indices"
    #   role.members.map{ |grant| grant.member.role_id } # => ['conjur:user:jon', 'conjur:robot:rebuild_indices']
    #   api.role('user:jon').admin_of?(role) # => true
    #
    #
    # @param [String] role a qualified role identifier for the new role
    # @param [Hash] options options for the action
    # @option options [String] :acting_as the resource will effectively be created by this role
    # @return [Conjur::Role] the created role
    # @raise [RestClient::MethodNotAllowed] if the role already exists.  Note that this differs from
    #   the `RestClient::Conflict` exception raised when trying to create existing high level (user, group, etc.)
    #   Conjur assets.
    def create_role(role, options = {})
      role(role).tap do |r|
        r.create(options)
      end
    end

    # Return a {Conjur::Role} representing a role with the given id.  Note that the {Conjur::Role} may or
    # may not exist (see {Conjur::Exists#exists?}).
    #
    # ### Permissions
    # Because this method returns roles that may or may not exist, it doesn't require any permissions to call it:
    # in fact, it does not perform an HTTP request (except for authentication if necessary).
    #
    # @example Create and show a role
    #   api.create_role 'cat:iggy'
    #   iggy = api.role 'cat:iggy'
    #   iggy.exists? # true
    #   iggy.members.map(&:member).map(&:roleid) # => ['conjur:user:admin']
    #   api.current_role.roleid # => 'conjur:user:admin' # creator role is a member of created role.
    #
    # @example No permissions are required to call this method
    #   api.current_role # => "user:no-access"
    #
    #   # current role is only a member of itself, so it can't see other roles.
    #   api.current_role.memberships.count # => 1
    #   admin = api.role 'user:admin' # OK
    #   admin.exists? # => true
    #   admin.members # => RestClient::Forbidden: 403 Forbidden
    #
    # @param [String] role the id of the role, which must contain at least kind and id tokens (account is optional).
    # @return [Conjur::Role] an object representing the role
    def role role
      Role.new(Conjur::Authz::API.host, credentials)[self.class.parse_role_id(role).join('/')]
    end

    # Return a {Conjur::Role} object representing the role (typically a user or host) that this api is authenticated
    # as.  This is derived either from the `login` argument to {Conjur::API.new_from_key} or from the contents of the
    # `token` given to {Conjur::API.new_from_token}.
    #
    # @example Current role for a user
    #   api = Conjur::API.new_from_key 'jon', 'somepassword'
    #   api.current_role.roleid # => 'conjur:user:jon'
    #
    # @example Current role for a host
    #   host = api.create_host id: 'exapmle-host'
    #
    #   # Host and User have an `api` method that returns an api with their credentials.  Note
    #   # that this only works with a newly created host or user, which has an `api_key` attribute.
    #   host.api.current_role.roleid # => 'conjur:host:example-host'
    #
    # @return [Conjur::Role] the authenticated role for this API instance
    def current_role
      role_from_username username
    end


    #@!endgroup

    # @api private
    #
    # Get a Role instance from a username or host id
    # @param [String] username the username or host id
    # @return [Conjur::Role]
    def role_from_username username
      role(role_name_from_username username)
    end

    # @api private
    #
    # Convert a username or host id to a role identifier.
    # This handles conversion of logins like 'host/foo' to 'host:foo'
    # @param [String] username the user name or host id
    # @return [String] A full role id for the user or host
    def role_name_from_username username = self.username
      tokens = username.split('/')
      if tokens.size == 1
        [ 'user', username ].join(':')
      else
        [ tokens[0], tokens[1..-1].join('/') ].join(':')
      end
    end

    private

    # @api  private
    # Use of this method is deprecated in favor of Conjur::Cast#cast
    # @deprecated
    # @param [String, Conjur::Role] role object to extract a role id from
    # @return [String] the role id
    def normalize_roleid role
      case role
        when String then role
        when Role then role.roleid
          else raise "Can't normalize #{role}@#{role.class}"
      end
    end
  end
end
