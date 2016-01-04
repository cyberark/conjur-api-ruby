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
require 'conjur/host_factory_token'

module Conjur
  class HostFactory < RestClient::Resource
    include ActsAsAsset
    
    def roleid
      attributes['roleid']
    end
    
    def role
      Role.new(Conjur::Authz::API.host, self.options)[Conjur::API.parse_role_id(roleid).join('/')]
    end
    
    def deputy
      Conjur::Deputy.new(Conjur::API.core_asset_host, options)["deputies/#{fully_escape id}"]
    end

    def deputy_api_key
      attributes['deputy_api_key']
    end
    
    def create_token(expiration, options = {})
      create_tokens(expiration, 1, options)[0]
    end
    
    def create_tokens(expiration, count, options = {})
      parameters = options.merge({
        expiration: expiration.iso8601,
        count: count
      })
      response = RestClient::Resource.new(Conjur::API.host_factory_asset_host, self.options)[fully_escape id]["tokens"].post(parameters).body
      JSON.parse(response).map do |attrs|
        build_host_factory_token attrs
      end
    end

    def tokens
      # Tokens list is not returned by +show+ if the caller doesn't have permission
      return nil unless self.attributes['tokens']

      self.attributes['tokens'].collect do |attrs|
        build_host_factory_token attrs
      end
    end
    
    protected
    
    def build_host_factory_token attrs
      Conjur::HostFactoryToken.new(Conjur::API.host_factory_asset_host, self.options)["tokens"][attrs['token']].tap do |token|
        token.attributes = attrs
      end
    end
  end
end
