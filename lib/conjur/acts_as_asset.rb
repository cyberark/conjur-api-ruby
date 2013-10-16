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
  module ActsAsAsset
    def self.included(base)
      base.instance_eval do
        include HasId
        include Exists
        include HasOwner
        include ActsAsResource
        include HasAttributes
      end
      
      def add_member(role_name, member, options = {})
        owned_role(role_name).grant_to member, options
      end
      
      def remove_member(role_name, member)
        owned_role(role_name).revoke_from member
      end
      
      protected
      
      def owned_role(role_name)
        tokens = [ resource_kind, resource_id, role_name ]
        grant_role = [ core_conjur_account, '@', tokens.join('/') ].join(':')
        require 'conjur/role'
        Conjur::Role.new(Conjur::Authz::API.host, self.options)[Conjur::API.parse_role_id(grant_role).join('/')]
      end
    end
  end
end