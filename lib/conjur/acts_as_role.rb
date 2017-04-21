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

    # Find all roles of which this role is a member.  By default, role relationships are recursively expanded,
    # so if `a` is a member of `b`, and `b` is a member of `c`, `a.all` will include `c`.
    #
    # ### Permissions
    # You must be a member of the role to call this method.
    #
    # You can restrict the roles returned to one or more role ids.  This feature is mainly useful
    # for checking whether this role is a member of any of a set of roles.
    #
    # ### Options
    #
    # * **recursive** Defaults to +true+, performs recursive expansion of the memberships.
    #
    # @example Show all roles of which `"conjur:group:pubkeys-1.0/key-managers"` is a member
    #   # Add alice to the group, so we see something interesting
    #   key_managers = api.group('pubkeys-1.0/key-managers')
    #   key_managers.add_member api.user('alice')
    #
    #   # Show the memberships, mapped to the member ids.
    #   key_managers.role.all.map(&:roleid)
    #   # => ["conjur:group:pubkeys-1.0/admin", "conjur:user:alice"]
    #
    # @example See if role `"conjur:user:alice"` is a member of either `"conjur:groups:developers"` or `"conjur:group:ops"`
    #   is_member = api.role('conjur:user:alice').all(filter: ['conjur:group:developers', 'conjur:group:ops']).any?
    #
    # @param [Hash] options options for the request
    # @param options [Hash, nil] :filter only return roles in this list. Also, extra parameters to pass to the webservice method.
    # @return [Array<Conjur::Role>] Roles of which this role is a member
    def memberships(options = {})
      request = if options.delete(:recursive) == false
        options["memberships"] = true
      else
        options["all"] = true
      end
      if filter = options.delete(:filter)
        filter = [filter] unless filter.is_a?(Array)
        options["filter"] = filter.map{ |obj| cast(obj, :roleid) }
      end

      result = JSON.parse(rbac_role_resource[options_querystring options].get)
      if result.is_a?(Hash) && ( count = result['count'] )
        count
      else
        host = Conjur.configuration.core_url
        result.collect do |item|
          if item.is_a?(String)
            build_object item
          else
            RoleGrant.parse_from_json(item, self.options)
          end
        end
      end
    end

    # Check to see if this role is a member of another role.  Membership is transitive.
    #
    # ### Permissions
    # You must be logged in as a member of this role in order to call this method.  Note that if you
    # pass a role of which you aren't a member to this method, it will return false rather than raising an
    # exception.
    #
    # @example Permissions
    #   alice_api = Conjur::API.new_from_key "alice", "alice-password"
    #   admin_api = Conjur::API.new_from_key "admin", "admin-password"
    #
    #   # admin_view is the role as seen by the admin user
    #   admin_view = admin_api.role('conjur:group:pubkeys-1.0/key-managers')
    #   admin_view.member_of? alice_api.current_role # => false
    #   alice_api.current_role.member_of? admin_view # => false
    #
    #   # alice_view is the role as seen by alice (who isn't a member of the key-managers group)
    #   alice_view = alice_api.role('conjur:group:pubkeys-1.0/key-managers')
    #   alice_view.member_of? alice_api.current_role # raises RestClient::Forbidden
    #   alice_api.current_role.member_of? alice_view # false
    #
    # @param [String, #roleid] other_role the role or role id of which we might be a member
    # @return [Boolean] whether this role is a member of `other_role`
    # @raise [RestClient::Forbidden] if you don't have permission to perform this operation
    def member_of?(other_role)
      other_role = cast(other_role, :roleid)
      not all(filter: other_role).empty?
    end

    # Check to see if this role is allowed to perform `privilege` on `resource`.
    #
    # ### Permissions
    # Any authenticated role may call this method.  However, instead of raising a 404 if a resource
    # or role doesn't exist, it will return false.  This is to prevent bad guys from finding out which roles
    # and resources exist.
    #
    # @example
    #   bacon = api.create_resource 'food:bacon'
    #   eggs  = api.create_resoure 'food:eggs'
    #   bob = api.create_role 'cook:bob'
    #
    #   # Bob can't do anything initially
    #   bob.permitted? bacon, 'fry' # => false
    #   bob.permitted? eggs, 'poach' # => false
    #
    #   # Let him poach eggs
    #   eggs.permit 'poach', bob
    #
    #   # Now it's permitted
    #   bob.permitted? eggs, 'poach' # => true
    #
    # @example Somethign a bit more realistic
    #   # Say we have a service layer that needs access to a database connection string.
    #   # The layer is called 'web', and the connection string is stored in a variable 'mysql-uri'
    #   web_layer = api.layer 'web'
    #   mysql_uri = api.variable 'mysql-uri'
    #
    #   # The web layer can't see the value of the variable right now:
    #   web_layer.role.permitted? mysql_uri, 'execute' # => false
    #
    #   # Let's permit that
    #   mysql_uri.permit 'execute', web_layer
    #
    #   # Now it's allowed to fetch the connection string
    #  web_layer.role.permitted? mysql_uri, 'execute' # => true
    #
    # @param [#resourceid, String] resource the resource to check the permission against
    # @param [String] privilege the privilege to check
    # @return [Boolean] true if this role has the privilege on the resource
    def permitted?(resource, privilege, options = {})
      resource = cast(resource, :resourceid)
      # NOTE: in previous versions there was 'kind' passed separately. Now it is part of id
      rbac_role_resource["?check&resource_id=#{query_escape resource}&privilege=#{query_escape privilege}"].get(options)
      true
    rescue RestClient::ResourceNotFound
      false
    end
    
    # Fetch the direct members of this role. The results are *not* recursively expanded).
    #
    # ### Permissions
    # You must be a member of the role to call this method.
    # 
    # @param options [Hash, nil] extra parameters to pass to the webservice method.
    # @return [Array<Conjur::RoleGrant>] the role memberships
    # @raise [RestClient::Forbidden] if you don't have permission to perform this operation
    def members options = {}
      options["members"] = true
      result = JSON.parse(rbac_role_resource[options_querystring options].get)
      if result.is_a?(Hash) && ( count = result['count'] )
        count
      else
        result['members'].collect do |json|
          RoleGrant.parse_from_json(json, credentials)
        end
      end
    end
  end
end