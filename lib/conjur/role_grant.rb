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
  # A `RoleGrant` instance represents the membership of a role in some unspecified role.  `RoleGrant`s are returned
  # by {Conjur::Role#members} and represent members of the role on which the method was invoked.
  #
  # @example
  #   alice.members.map{|grant| grant.member}.include? admin_role # => true
  #   admin_role.members.map{|grant| grant.member}.include? alice # => true
  #
  class RoleGrant


    # The member role in the relationship
    # @return [Conjur::Role] the member
    attr_reader :member

    # The role that created this grant.
    #
    # @return [Conjur::Role] the role that created the grant
    attr_reader :grantor

    # When true, the role {#member} is allowed to give this grant to other roles
    #
    # @return [Boolean] whether the role can grant the role to others
    attr_reader :admin_option


    # @api private
    #
    # Create a new RoleGrant instance.
    #
    # @param [Conjur::Role] member the member to which the role was granted
    # @param [Conjur::Role] grantor  the role that created this grant
    # @param [Boolean] admin_option whether `member` can give the grant to other roles
    def initialize member, grantor, admin_option
      @member = member
      @grantor = grantor
      @admin_option = admin_option
    end

    #@!attribute member
    #   The member thing
    #   @return [Conjur::Role] a ret?

    class << self
      # @api private
      #
      # Create a `RoleGrant` from a JSON respnose
      #
      # @param [Hash] json the parsed JSON response
      # @param [Hash] credentials the credentials used to create APIs for the member and grantor role objects
      # @return [Conjur::RoleGrant]
      def parse_from_json(json, credentials)
        member = Role.new(Conjur::Authz::API.host, credentials)[Conjur::API.parse_role_id(json['member']).join('/')]
        grantor = Role.new(Conjur::Authz::API.host, credentials)[Conjur::API.parse_role_id(json['grantor']).join('/')]
        RoleGrant.new(member, grantor, json['admin_option'])
      end
    end
  end
end
