#
# Copyright (C) 2013-2015 Conjur Inc
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
    ##
    # Fetch a digraph (or a forest of digraphs) representing of
    #   role memberships related transitively to any of a list of roles.
    #
    # @param [Array<Conjur::Role, String>] roles the  digraph (or forest thereof) of
    #   the ancestors and descendants of these roles or role ids will be returned
    # @param [Hash] options options determining the graph returned
    # @option opts [Boolean] :ancestors Whether to return ancestors of the given roles (true by default)
    # @option opts [Boolean] :descendants Whether to return descendants of the given roles (true by default)
    # @option opts [Conjur::Role, String] :as_role Only roles visible to this role will be included in the graph
    # @return [Conjur::Graph] An object representing the role memberships digraph
    def role_graph roles, options = {}
      roles.map!{|r| normalize_roleid(r) }
      options[:as_role] = normalize_roleid(options[:as_role]) if options.include?(:as_role)
      options.reverse_merge! as_role: normalize_roleid(current_role), descendants: true, ancestors: true

      query = {from_role: options.delete(:as_role)}
        .merge(options.slice(:ancestors, :descendants))
        .merge(roles: roles).to_query
      Conjur::Graph.new Conjur::REST.new(Conjur::Authz::API.host, credentials)\
          ["#{Conjur.account}/roles?#{query}"].get
    end

    def create_role(role, options = {})
      role(role).tap do |r|
        r.create(options)
      end
    end

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
