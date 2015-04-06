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
  #   admin_role.members.map{|grant| grant.member}.include? alice # => false
  RoleGrant = Struct.new(:member, :grantor, :admin_option) do
    #@!attribute [r] member
    # @return [Conjur::Role] the member role

    #@!attribute [r] grantor
    # @return [Conjur::Role] the role that granted this membership

    #@!attribute [r] admin_option
    # @return [Boolean] whether {#member} is allowed to transfer the grant to other roles

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