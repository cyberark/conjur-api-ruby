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
        response = RestClient::Resource.new(Conjur::API.host_factory_asset_host, http_options)["hosts"].post(options.merge(id: id)).body
        JSON.parse(response)
      end
    end
    
    # Options:
    # +layers+ list of host factory layers
    # +roleid+ host factory role id
    # +role+ host factory role. If this is provided, it is converted to roleid.
    def create_host_factory(id, options = {})
      if options[:layers]
        options[:layers] = options[:layers].map do |layer|
          if layer.is_a?(Conjur::Layer)
            layer.id
          elsif layer.is_a?(String)
            layer
          else
            raise "Can't interpret layer #{layer}"
          end
        end
      end
      if role = options.delete(:role)
        options[:roleid] = role.roleid
      end
      log do |logger|
        logger << "Creating host_factory #{id}"
        unless options.blank?
          logger << " with options #{options.inspect}"
        end
      end
      options ||= {}
      options[:id] = id
      resp = RestClient::Resource.new(Conjur::API.host_factory_asset_host, credentials).post(options)
      Conjur::HostFactory.build_from_response(resp, credentials)
    end
    
    def host_factory id
      Conjur::HostFactory.new(Conjur::API.host_factory_asset_host, credentials)[fully_escape(id)]
    end

    def revoke_host_factory_token token
      token = token.token if token.is_a?(Conjur::HostFactoryToken)
      RestClient::Resource.new(Conjur::API.host_factory_asset_host, credentials)["tokens/#{token}"].delete
    end
    
    def show_host_factory_token token
      token = token.token if token.is_a?(Conjur::HostFactoryToken)
      attrs = JSON.parse(RestClient::Resource.new(Conjur::API.host_factory_asset_host, credentials)["tokens/#{token}"].get.body)
      Conjur::HostFactoryToken.new(Conjur::API.host_factory_asset_host, credentials)["tokens"][attrs['token']].tap do |token|
        token.attributes = attrs
      end
    end
    
    # Creates a Host and returns a Host object.
    def host_factory_create_host token, id, options = {}
      attributes = self.class.host_factory_create_host token, id, options
      Conjur::Host.new(Conjur::API.core_asset_host, credentials)["hosts"][fully_escape attributes['id']].tap do |host|
        host.attributes = attributes
      end
    end
  end
end
