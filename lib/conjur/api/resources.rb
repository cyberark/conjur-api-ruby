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
require 'conjur/resource'

module Conjur
  class API
    #@!group Authorization: Resources

    # Create a {http://developer.conjur.net/reference/services/authorization/resource Conjur Resource}.
    # Resources are entities on which roles have permissions.  A resource might represent a secret, a
    # web service route, or be part of a higher level construct such as a user or group.
    #
    # If `:acting_as` is not present in `options`, you will be the owner of the new role.  If it is present,
    # your role must be a member of the given role (see {Conjur::Role#member_of?}).
    #
    # @example Create an abstract resource to represent a web service route
    #   # Notice that we can omit the account in the identifier
    #   service_resource = api.create_resource 'web-service:list-gadgets'
    #   service_resource.resource_id # => 'conjur:web-service:list-gadgets'
    #
    #   # In a gatekeeper for the web service, we can use the resource to control access
    #   get '/gadgets' do
    #     # We'll assume that we've verified the Conjur authn token in the request, and stored the
    #     # corresponding identifier in `request_role_id`
    #     halt(403) unless api.resource('conjur:web-service:list-gadgets').permitted? 'read', request_role_id
    #     render_json find_gadgets
    #   end
    #
    # @example Create a role owned by another role
    #   alice = api.role('user:alice')
    #   api.current_role.member_of? alice # true, the operation will fail if this is false
    #   res = api.create_resource 'example:owned', acting_as: 'user:alice'
    #   res.owner # "conjur:user:alice"
    #
    # @param [String] identifier an id of the form `"<account>:<kind>:<id>"` or `"<kind>:<id>"`
    # @param options [Hash] options for the request
    # @option options [String, #role_id] :acting_as the role-ish thing or role id that will own the new resource
    # @return [Conjur::Role] the new role
    def create_resource(identifier, options = {})
      resource(identifier).tap do |r|
        r.create(options)
      end
    end
    
    # Find a resource by it's id.  The id given to this method must be qualified by a kind, but the account is
    # optional.
    #
    # ### Permissions
    #
    # The resource **must** be visible to the current role.  This is the case if the current role is the owner of
    # the resource, or has any privilege on it.
    #
    # @example Find or create a resource
    #    def find_or_create_resource resource_id
    #       resource = api.resource resource_id
    #       unless resource.exists?
    #         resource = api.create_resource resource_id
    #       end
    #       resource
    #     end
    #
    #     # ...
    #     example_resource = find_or_create_resource 'example:find-or-create'
    #     example_resource.exists? # always true
    #
    # @param identifier [String] a qualified resource identifier, optionally including an account
    # @return [Conjur::Resource] the resource, which may or may not exist
    def resource identifier
      Resource.new(Conjur::Authz::API.host, credentials)[self.class.parse_resource_id(identifier).join('/')]
    end

    # Find all resources visible to the current role that match the given search criteria.
    #
    # ## Full Text Search
    # Conjur supports full text search over the identifiers and annotation *values*
    # of resources.  For example, if `opts[:search]` is `"pubkeys"`, any resource with
    # an id containing `"pubkeys"` or an annotation whose value contains `"pubkeys"` will match.
    #
    # **Notes**
    #   * Annotation *keys* are *not* indexed for full text search.
    #   * Conjur indexes the content of ids and annotation values by word.
    #   * Only resources visible to the current role (either owned by that role or
    #       having a privilege on it) are returned.
    #   * If you do not provide `:offset` or `:limit`, all records will be returned. For systems
    #       with a huge number of resources, you may want to paginate as shown in the example below.
    #   * If `:offset` is provided and `:limit` is not, 10 records starting at `:offset` will be
    #       returned.  You may choose an arbitrarily large number for `:limit`, but the same performance
    #       considerations apply as when omitting `:offset` and `:limit`.
    #
    # @example Search for resources annotated with the text "WebService Route"
    #    webservice_routes = api.resources search: "WebService Route"
    #
    #    # Check that it worked:
    #    webservice_routes.each do |resource|
    #       searchable = [resource.annotations.to_h.values, resource.resource_id]
    #       raise "FAILED" unless searchable.flatten.any?{|s| s.include? "WebService Route"}
    #    end
    #
    # @example Restrict the search to 'group' resources
    #   groups = api.resources kind: 'group'
    #
    #   # Correct behavior:
    #   expect(groups.all?{|g| g.kind == 'group'}).to be_true
    #
    #
    # @example Get every single resource in a performant way
    #   resources = []
    #   limit = 25
    #   offset = 0
    #   until (batch = api.resources limit: limit, offset: offset).empty?
    #     offset += batch.length
    #     resources.concat results
    #   end
    #   # do something with your resources
    #
    # @param opts [Hash] search criteria
    # @option opts [String]   :search find resources whose ids or annotations contain this string
    # @option opts [String]   :kind find resources whose `kind` matches this string
    # @option opts [Integer]  :limit the maximum number of records to return (Conjur may return fewer)
    # @option opts [Integer]  :offset offset of the first record to return
    # @return [Array<Conjur::Resource>] the resources matching the criteria given
    def resources opts = {}
      opts = { host: Conjur::Authz::API.host, credentials: credentials }.merge opts
      opts[:account] ||= Conjur.account
      
      Resource.all(opts).map do |result|
        resource(result['id']).tap do |r|
          r.attributes = result
        end
      end
    end

    # The resource which grants global privileges to Conjur.
    # Privileges given on this resource apply to any record in the system.
    # There are two defined global privileges:
    #
    # * **sudo** permission is granted for any action. 
    # * **reveal** methods which list records will always return every matching
    #   record, regardless of whether the user has any privileges on these records or not.
    #   Services can also choose to attach additional semantics to *reveal*, such as allowing
    #   the user to show non-sensitive attributes of any record.
    #
    # Global privileges are available in Conjur 4.5 and later.
    GLOBAL_PRIVILEGE_RESOURCE = "!:!:conjur"
    
    # Checks whether the client has a particular global privilege.
    # The global privileges are *sudo* and *reveal*.
    def global_privilege_permitted? privilege
      resource(GLOBAL_PRIVILEGE_RESOURCE).permitted? privilege
    end
  end
end
