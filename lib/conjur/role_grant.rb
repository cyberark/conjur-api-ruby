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
  # Represents the membership of a role. `RoleGrant`s are returned
  # by {ActsAsRole#members} and represent members of the role on which the method was invoked.
  #
  # @example
  #   alice.members.map{|grant| grant.member}.include? admin_role # => true
  #   admin_role.members.map{|grant| grant.member}.include? alice # => true
  #
  class RoleGrant
    extend BuildObject::ClassMethods

    # The role which was granted.
    # @return [Conjur::Role]
    attr_reader :role

    # The member role in the relationship
    # @return [Conjur::Role]
    attr_reader :member

    # When true, the role {#member} is allowed to give this grant to other roles
    #
    # @return [Boolean]
    attr_reader :admin_option

    # @api private
    #
    # Create a new RoleGrant instance.
    #
    # @param [Conjur::Role] member the member to which the role was granted
    # @param [Boolean] admin_option whether `member` can give the grant to other roles
    def initialize role, member, admin_option
      @role = role
      @member = member
      @admin_option = admin_option
    end

    # Representation of the role grant as a hash.
    def to_h
      {
        role: role.id,
        member: member.id,
        admin_option: admin_option
      }
    end
    
    def to_s
      to_h.to_s
    end

    def as_json options = {}
      to_h.as_json(options)
    end

    class << self
      # @api private
      #
      # Create a `RoleGrant` from a JSON respnose
      #
      # @param [Hash] json the parsed JSON response
      # @param [Hash] credentials the credentials used to create APIs for the member and grantor role objects
      # @return [Conjur::RoleGrant]
      def parse_from_json(json, credentials)
        role = build_object(json['role'], credentials, default_class: Role)
        member = build_object(json['member'], credentials, default_class: Role)
        RoleGrant.new(role, member, json['admin_option'])
      end
    end
  end
end
