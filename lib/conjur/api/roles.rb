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

    # Create a {Conjur::Role} with the given id
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
    #
    def role role
      Role.new(Conjur::Authz::API.host, credentials)[self.class.parse_role_id(role).join('/')]
    end

    def current_role
      role_from_username username
    end

    def role_from_username username
      role(role_name_from_username username)
    end

    def role_name_from_username username = self.username
      tokens = username.split('/')
      if tokens.size == 1
        [ 'user', username ].join(':')
      else
        [ tokens[0], tokens[1..-1].join('/') ].join(':')
      end
    end

    #@!endgroup

    private
    def normalize_roleid role
      case role
        when String then role
        when Role then role.roleid
          else raise "Can't normalize #{role}@#{role.class}"
      end
    end
  end
end
