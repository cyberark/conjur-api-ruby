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

require 'conjur/host_factory'

module Conjur
  class API
    #@!group Host Factory

    class << self
      # Use a host factory token to create a new host. Unlike most other methods, this
      # method does not require a Conjur access token. The host factory token is the
      # authentication and authorization to create the host.
      #
      # The token must be valid. The host id can be a new host, or an existing host. 
      # If the host already exists, the server verifies that its layer memberships
      # match the host factory exactly. Then, its API key is rotated and returned with
      # the response.
      # 
      # @param [String] token the host factory token.
      # @param [String] id the id of a new or existing host.
      # @param options [Hash] additional host creation options.
      # @return [Host]
      def host_factory_create_host token, id, options = {}
        token = token.token if token.is_a?(HostFactoryToken)
        response = url_for(:host_factory_create_host, token).post(options.merge(id: id)).body
        attributes = JSON.parse(response)
        Host.new(attributes['id'], {}).tap do |host|
          host.attributes = attributes
        end
      end
      
      # Revokes a host factory token. After revocation, the token can no longer be used to 
      # create hosts.
      # 
      # @param [Hash] credentials authentication credentials of the current user.
      # @param [String] token the host factory token.
      def revoke_host_factory_token credentials, token
        url_for(:host_factory_revoke_token, credentials, token).delete
      end
    end
    
      # Revokes a host factory token. After revocation, the token can no longer be used to 
      # create hosts.
      # 
      # @param [String] token the host factory token.
    def revoke_host_factory_token token
      self.class.revoke_host_factory_token credentials, token
    end

    #@!endgroup
  end
end
