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
require 'conjur/role_grant'

module Conjur
  # A {http://developer.conjur.net/reference/services/authorization/role Conjur Role} represents an actor that
  # can be granted or denied permissionto do various things to
  # {http://developer.conjur.net/reference/services/authorization/resource Conjur Resources}.  Roles are hierarchical:
  # if role a is a **member of** role b, a is permitted to do everything b is permitted
  # to do.  This relationship is transitive, so if a is a member of b, b is a member of c,
  # and c is a member of d, a has all of d's permissions.
  #
  # This class represents a Role with a particular identifier.  The actual Conjur role *may or may not
  # exist!*
  class Role < RestClient::Resource
    include Exists
    include PathBased

    # The *unqualified* identifier for this role.
    #
    # @example
    #   api.role('conjur:foo:bar').identifier # => "bar"
    #
    # @return [String] the unqualified identifier
    def identifier
      match_path(3..-1)
    end
    
    alias id identifier

    # The *qualified* identifier for this role.
    #
    # @example
    #   api.user('bob').role_id # => "conjur:user:bob"
    #
    # @return [String] the *qualified* identifier
    def roleid
      [ account, kind, identifier ].join(':')
    end

    alias role_id roleid

    # @api private
    # Create this role.
    #
    # You probably want to use {Conjur::API#create_role} instead.
    def create(options = {})
      log do |logger|
        logger << "Creating role #{kind}:#{identifier}"
        unless options.empty?
          logger << " with options #{options.to_json}"
        end
      end
      self.put(options)
    end

    # Find all roles of which this role is a member.  This relationship is recursively expanded,
    # so if `a` is a member of `b`, and `b` is a member of `c`, `a.all` will include `c`.
    #
    # ### Permissions
    # You must be a member of the role to call this method.
    #
    # You can restrict the roles returned to one or more role ids.  This feature is mainly useful
    # for checking whether this role is a member of any of a set of roles.
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
    # @option options [String, #roleid, Array<String, #roleid>] :filter only return roles in this list
    # @return [Array<Conjur::Role>] Roles of which this role is a member
    def all(options = {})
      query_string = "?all"
      
      if filter = options.delete(:filter)
        filter = [filter] unless filter.is_a?(Array)
        filter.map!{ |obj| cast(obj, :roleid) }
        (query_string << "&" << filter.to_query("filter")) unless filter.empty?
      end
      JSON.parse(self[query_string].get(options)).collect do |id|
        Role.new(Conjur::Authz::API.host, self.options)[Conjur::API.parse_role_id(id).join('/')]
      end
    end
    
    alias memberships all

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

    # Grant this role to another one.  The role given by the `member` argument will become
    # a member of this role, and have all of its permissions.
    #
    # ### Permissions
    # You must have admin permissions on this role.
    #
    # @example Allow `'alice'` to do everything that `'bob'` can do (perhaps better!).
    #   bob = api.role 'cook:bob'
    #   alice = api.role 'cook:alice'
    #
    #   # bob is allowed to 'fry' a resource called 'food:bacon'
    #   bob.permitted? "food:bacon", "fry" # => true
    #
    #   # alice isn't
    #   alice.permitted? "food:bacon", "fry" # => false
    #
    #   # grant the role 'cook:bob'  to alice, so that she can participate in our culture's
    #   # bizarre bacon obsession!
    #   bob.grant_to alice
    #
    #   # Now she can fry some bacon!
    #   alice.permitted? 'food:bacon', 'fry' # => true
    #
    # @example Make `alice` a member of `job:cook`, and let her grant that role to others
    #   # Create an api logged in as 'alice'.  We assume that `api` is an admin.
    #   alice_api = Conjur::API.new_from_key 'alice', 'alice-password'
    #
    #   # First do it without the `admin_option`
    #   api.role('job:cook').grant_to alice_api.current_role
    #
    #   # Alice can't grant the role to bob
    #   alice_api.role('job:cook').grant_to 'user:bob' # => raises RestClient::Forbidden
    #
    #   # Make alice an admin of the role
    #   api.role('job:cook').grant_to alice_api.current_role, admin_option: true
    #
    #   # Now she can grant the role to bob
    #   alice_api.role('job:cook').grant_to 'user:bob' # Works!
    #
    # @example Take away a member's admin privilege
    #   # alice_api is an api logged in as user "alice", who has admin rights on the role 'job:cooks'.
    #   # Notice that she can grant the role to 'eve'
    #   alice_api.role('job:cook').grant_to 'eve'
    #
    #   # We don't want her to do this any more
    #   admin_api.role('job:cook').grant_to 'user:alice', admin_option: false
    #
    #   # She's still a member
    #   alice_api.member_of?('job:cook') # => true
    #
    #   # But she can't grant the role to 'bob'
    #   alice_api.role('job:cook').grant_to 'user:bob' # raises RestClient:Forbidden
    #
    # @param [String, #roleid] member the role that will become a member of this role
    # @param [Hash] options options for the grant
    # @option options [Boolean] :admin_option when given, the admin flag on the role grant will be set to
    #   this value.
    # @return [void]
    # @raise [RestClient::Forbidden] if you don't have permission to perform the operation
    def grant_to(member, options={})
      member = cast(member, :roleid)
      log do |logger|
        logger << "Granting role #{identifier} to #{member}"
        unless options.blank?
          logger << " with options #{options.to_json}"
        end
      end
      self["?members&member=#{query_escape member}"].put(options)
    end

    # Remove (revoke) a member from this role. This operation is the inverse of {#grant_to}
    #
    # ### Permissions
    # You must have admin permissions on this role
    #
    #
    # @example Bob has been fired from his job as a cook.
    #   # currently, he's a member, and therefore is allowed to 'fry' the 'bacon' resource
    #   bob = api.role('user:bob')
    #   bob.member_of? 'job:cook' # true
    #   bob.permitted? 'food:bacon', 'fry' # true
    #
    #   # Revoke 'job:cook'
    #   api.role('job:cook').revoke_from 'user:bob'
    #
    #   # Now he's not a member, and he can't fry bacon any more
    #   bob.member_of? 'job:cook' # false
    #   bob.permitted? 'food:bacon', 'fry' # false
    #
    #   # Note that if alice had her bacon frying permissions through her membership in the role 'user:bob',
    #   # she'll lose them too:
    #   api.role('user:alice').member_of? 'user:bob' # true
    #   api.role('user:alice').permitted? 'food:bacon', 'fry' # => false
    #
    #
    # @param [String, #roleid] member the member to revoke this role from
    # @param [Hash] options included for backwards compatibility.  Don't use it.
    # @return [void]
    # @raise [RestClient::Forbidden] If you don't have permission to perform this operation
    def revoke_from(member, options = {})
      member = cast(member, :roleid)
      log do |logger|
        logger << "Revoking role #{identifier} from #{member}"
        unless options.empty?
          logger << " with options #{options.to_json}"
        end
      end
      self["?members&member=#{query_escape member}"].delete(options)
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
      self["?check&resource_id=#{query_escape resource}&privilege=#{query_escape privilege}"].get(options)
      true
    rescue RestClient::ResourceNotFound
      false
    end
    

    # Fetch the members of this role. The results are *not* recursively expanded (in contrast to {#memberships}).
    #
    # ### Permissions
    # You must be a member of the role to call this method.
    # 
    # @param [Hash] options unused and included only for backwards compatibility 
    # @return [Array<Conjur::RoleGrant>] the role memberships
    # @raise [RestClient::Forbidden] if you don't have permission to perform this operation
    def members
      JSON.parse(self["?members"].get(options)).collect do |json|
        RoleGrant.parse_from_json(json, self.options)
      end
    end
  end
end
