#
# Copyright (C) 2014 Conjur Inc
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
require 'conjur/host_factory'

module Conjur
  class API
    class << self
      # Creates a host and returns the response Hash.
      def host_factory_create_host token, id, options = {}
        token = token.token if token.is_a?(HostFactoryToken)
        http_options = {
          headers: { authorization: %Q(Token token="#{token}") }
        }
        response = RestClient::Resource.new(Conjur.configuration.core_url, http_options)["host_factories"]["hosts"].post(options.merge(id: id)).body
        attributes = JSON.parse(response)
        Host.new(attributes['id'], {}).tap do |host|
          host.attributes = attributes
        end
      end
      
      # Revokes a host factory token.
      def revoke_host_factory_token credentials, token
        RestClient::Resource.new(Conjur.configuration.core_url, credentials)['host_factory_tokens'][token].delete
      end
    end
    
    # Revokes a host factory token.
    def revoke_host_factory_token token
      self.class.revoke_host_factory_token credentials, token
    end
  end
end
