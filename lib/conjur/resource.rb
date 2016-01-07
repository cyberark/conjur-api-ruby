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
require 'conjur/annotations'

module Conjur

  # A `Conjur::Resource` instance represents a Conjur
  # {http://developer.conjur.net/reference/services/authorization/resource Resource}.
  #
  # You should not instantiate this class directly.  Instead, you can get an instance from the
  # {Conjur::API#resource} and {Conjur::API#resources} methods, or from the {ActsAsResource#resource} method
  # present on objects representing Conjur assets that have associated resources.
  #
  class Resource < RestClient::Resource
    include HasAttributes
    include PathBased
    include Exists

    # The identifier part of the `resource_id` for this resource.  The identifier
    # is the resource id without the `account` and `kind` parts.
    #
    # @example
    #   resource = api.resource 'conjur:layer:pubkeys-1.0/public-keys'
    #   resource.identifier # => 'pubkeys-1.0/public-keys'
    #
    # @return [String] the identifier part of the id.
    def identifier
      match_path(3..-1)
    end

    # The full role id of the role that owns this resource.
    #
    # @example
    #   api.current_role # => 'conjur:user:jon'
    #   resource = api.create_resource 'conjur:example:resource-owner'
    #   resource.owner # => 'conjur:user:jon'
    #
    # @return [String] the full role id of this resource's owner.
    def ownerid
      attributes['owner']
    end

    alias owner ownerid
    
    # Return the full id for this resource.  The format is `account:kind:identifier`
    #
    # @example
    #   resource = api.layer('pubkeys-1.0/public-keys').resource
    #   resource.account        # => 'conjur'
    #   resource.kind           # => 'layer'
    #   resource.identifier     # => 'pubkeys-1.0/public-keys'
    #   resource.resourceid     # => 'conjur:layer:pubkeys-1.0/public-keys'
    # @return [String]
    def resourceid 
      [account, kind, identifier].join ':'
    end
    
    alias :resource_id :resourceid


    # @api private
    def create(options = {})
      log do |logger|
        logger << "Creating resource #{resourceid}"
        unless options.empty?
          logger << " with options #{options.to_json}"
        end
      end
      self.put(options)
    end
    
    # Lists roles that have a specified permission on the resource.
    #
    # This will return only roles of which api.current_user is a member.
    #
    # @example
    #   resource = api.resource 'conjur:variable:example'
    #   resource.permitted_roles 'execute' # => ['conjur:user:admin']
    #   resource.permit 'execute', api.user('jon')
    #   resource.permitted_roles 'execute' # => ['conjur:user:admin', 'conjur:user:jon']
    #
    # @param permission [String] the permission
    # @param options [Hash, nil] extra options to pass to RestClient::Resource#get
    # @return [Array<String>] the ids of roles that have `permission` on this resource.
    def permitted_roles(permission, options = {})
      JSON.parse RestClient::Resource.new(Conjur::Authz::API.host, self.options)["#{account}/roles/allowed_to/#{permission}/#{path_escape kind}/#{path_escape identifier}"].get(options)
    end
    
    # Changes the owner of a resource.  You must be the owner of the resource
    # or a member of the owner role to do this.
    #
    # @example
    #     resource.owner # => 'conjur:user:admin'
    #     resource.give_to 'conjur:user:jon'
    #     resource.owner # => 'conjur:user:jon'
    #
    # @param owner [String, #roleid] the new owner.
    # @return [void]
    def give_to(owner, options = {})
      owner = cast(owner, :roleid)
      invalidate do
        self.put(options.merge(owner: owner))
      end

      nil
    end

    # @api private
    def delete(options = {})
      log do |logger|
        logger << "Deleting resource #{resourceid}"
        unless options.empty?
          logger << " with options #{options.to_json}"
        end
      end
      super options
    end

    # Grant `privilege` on this resource to `role`.
    #
    # This operation is idempotent, that is, nothing will happen if
    # you attempt to grant a privilege that the role already has on
    # this resource.
    #
    # @example
    #   user = api.user 'bob'
    #   resource = api.variable('example').resource
    #   resource.permitted_roles 'bake' # => ['conjur:user:admin']
    #   resource.permit 'fry', user
    #   resource.permitted_roles 'fry' # => ['conjur:user:admin', 'conjur:user:bob']
    #   resource.permit ['boil', 'bake'], bob
    #   resource.permitted_roles 'boil' # => ['conjur:user:admin', 'conjur:user:bob']
    #   resource.permitted_roles 'bake' # => ['conjur:user:admin', 'conjur:user:bob']
    #
    # @param privilege [String, #each] The privilege to grant, for example
    #   `'execute'`, `'read'`, or `'update'`.  You may also pass an `Enumerable`
    #   object, in which case the Strings yielded by #each will all be granted
    #
    # @param role [String, #roleid] The role-ish object or full role id
    #   to which the permission is to be granted/
    #
    # @param options [Hash, nil] options to pass through to `RestClient::Resource#post`
    #
    # @return [void]
    def permit(privilege, role, options = {})
      role = cast(role, :roleid)
      eachable(privilege).each do |p|
        log do |logger|
          logger << "Permitting #{p} on resource #{resourceid} by #{role}"
          unless options.empty?
            logger << " with options #{options.to_json}"
          end
        end
        
        begin
          self["?permit&privilege=#{query_escape p}&role=#{query_escape role}"].post(options)
        rescue RestClient::Forbidden
          # TODO: Remove once permit is idempotent
          raise $! unless $!.http_body == "Privilege already granted."
        end
      end
      nil
    end

    # The inverse operation of `#permit`.  Deny permission `privilege` to `role`
    # on this resource.
    #
    # @example
    #
    #   resource.permitted_roles 'execute' # => ['conjur:user:admin', 'conjur:user:alice']
    #   resource.deny 'execute', 'conjur:user:alice'
    #   resource.permitted_roles 'execute' # =>  ['conjur:user:admin']
    #
    # @param privilege [String, #each] A permission name or an `Enumerable` of permissions to deny.  In the
    #   later, all permissions will be denied.
    #
    # @param role [String, :roleid] A full role id or a role-ish object whose permissions we will deny.
    #
    # @return [void]
    def deny(privilege, role, options = {})
      role = cast(role, :roleid)
      eachable(privilege).each do |p|
        log do |logger|
          logger << "Denying #{p} on resource #{resourceid} by #{role}"
          unless options.empty?
            logger << " with options #{options.to_json}"
          end
        end
        self["?deny&privilege=#{query_escape p}&role=#{query_escape role}"].post(options)
      end
      nil
    end

    # True if the logged-in role, or a role specified using the :acting_as option, has the
    # specified +privilege+ on this resource.
    #
    # @example
    #   api.current_role # => 'conjur:cat:mouse'
    #   resource.permitted_roles 'execute' # => ['conjur:user:admin', 'conjur:cat:mouse']
    #   resource.permitted_roles 'update', # => ['conjur:user:admin', 'conjur:cat:gino']
    #
    #   resource.permitted? 'update' # => false, `mouse` can't update this resource
    #   resource.permitted? 'execute' # => true, `mouse` can execute it.
    #   resource.permitted? 'update',acting_as: 'conjur:cat:gino' # => true, `gino` can update it.
    # @param privilege [String] the privilege to check
    # @param [Hash, nil] options for the request
    # @option options [String,nil] :acting_as check whether the role given by this full role id is permitted
    #   instead of checking +api.current_role+.
    # @return [Boolean]
    def permitted?(privilege, options = {})
      # TODO this method should accept an optional role rather than putting it in the options hash.
      params = {
        check: true,
        privilege: query_escape(privilege)
      }
      params[:acting_as] = options[:acting_as] if options[:acting_as]
      self["?#{params.to_query}"].get(options)
      true
    rescue RestClient::Forbidden
      false
    rescue RestClient::ResourceNotFound
      false
    end

    # Return an {Conjur::Annotations} object to manipulate and view annotations.
    #
    # @see Conjur::Annotations
    # @example
    #    resource.annotations.count # => 0
    #    resource.annotations['foo'] = 'bar'
    #    resource.annotations.each do |k,v|
    #       puts "#{k}=#{v}"
    #    end
    #    # output is
    #    # foo=bar
    #
    #
    # @return [Conjur::Annotations]
    def annotations
      @annotations ||= Conjur::Annotations.new(self)
    end
    alias tags annotations

    # @api private
    # This is documented by Conjur::API#resources.
    # Returns all resources (optionally qualified by kind) visible to the user with given credentials.
    #
    #
    # Options are:
    # - host - authz url,
    # - credentials,
    # - account,
    # - kind (optional),
    # - search (optional),
    # - limit (optional),
    # - offset (optional).
    def self.all opts = {}
      host, credentials, account, kind = opts.values_at(*[:host, :credentials, :account, :kind])
      fail ArgumentError, "host and account are required" unless [host, account].all?

      credentials ||= {}

      path = "#{account}/resources" 
      path += "/#{kind}" if kind
      query = opts.slice(:acting_as, :limit, :offset, :search)
      path += "?#{query.to_query}" unless query.empty?
      resource = RestClient::Resource.new(host, credentials)[path]
      
      JSON.parse resource.get
    end

    protected


    # Given an Object, return something that responds to each.  In particular,
    # if `item.respond_to? :each` is true, we return the item, otherwise we put it in
    # an array.
    #
    # @param item [Object] the value we want to each over.
    # @return [#each]  `item` if item is already eachable, otherwise `[item]`.
    # @api private
    def eachable(item)
      item.respond_to?(:each) ? item : [ item ]
    end
  end
end
