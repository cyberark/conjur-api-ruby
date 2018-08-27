# frozen_string_literal: true

# Copyright 2013-2018 CyberArk Ltd.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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
    
    # Login name of the role. This is formed from the role kind and role id.
    # For users, the role kind can be omitted.
    def login
      [ kind, identifier ].delete_if{|t| t == "user"}.join('/')
    end

    # Check whether this object exists by performing a HEAD request to its URL.
    #
    # This method will return false if the object doesn't exist.
    #
    # @example
    #   does_not_exist = api.user 'does-not-exist' # This returns without error.
    #
    #   # this is wrong!
    #   owner = does_not_exist.members # raises RestClient::ResourceNotFound
    #
    #   # this is right!
    #   owner = if does_not_exist.exists?
    #     does_not_exist.members
    #   else
    #     nil # or some sensible default
    #   end
    #
    # @return [Boolean] does it exist?
    def exists?
      begin
        rbac_role_resource.head
        true
      rescue RestClient::Forbidden
        true
      rescue RestClient::ResourceNotFound
        false
      end
    end

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
    #   key_managers.role.all.map(&:id)
    #   # => ["conjur:group:pubkeys-1.0/admin", "conjur:user:alice"]
    #
    # @example See if role `"conjur:user:alice"` is a member of either `"conjur:groups:developers"` or `"conjur:group:ops"`
    #   is_member = api.role('conjur:user:alice').all(filter: ['conjur:group:developers', 'conjur:group:ops']).any?
    #
    # @param [Hash] options options for the request
    # @return [Array<Conjur::Role>] Roles of which this role is a member
    def memberships options = {}
      request = if options.delete(:recursive) == false
        options["memberships"] = true
      else
        options["all"] = true
      end
      if filter = options.delete(:filter)
        filter = [filter] unless filter.is_a?(Array)
        options["filter"] = filter.map{ |obj| cast_to_id(obj) }
      end

      result = JSON.parse(rbac_role_resource[options_querystring options].get)
      if result.is_a?(Hash) && ( count = result['count'] )
        count
      else
        host = Conjur.configuration.core_url
        result.collect do |item|
          if item.is_a?(String)
            build_object(item, default_class: Role)
          else
            RoleGrant.parse_from_json(item, self.options)
          end
        end
      end
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
        parser_for(:members, credentials, result)
      end
    end

    private

    # RestClient::Resource for RBAC role operations.
    def rbac_role_resource
      url_for(:roles_role, credentials, id)    
    end
  end
end
