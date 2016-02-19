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

require 'active_support/dependencies/autoload'
require 'active_support/core_ext'

module Conjur
  # @api private
  # This module provides a number of "standard" `REST` helpers,
  #   to wit, create, list and show.
  module StandardMethods
    
    protected

    # @api private
    #
    # Create this resource by sending a POST request to its URL.
    #
    # @param [String] host the url of the service (for example, https://conjur.host.com/api)
    # @param [String] type the asset `kind` (for example, 'user', 'group')
    # @param [String, nil] id the id of the new asset
    # @param [Hash] options options to pass through to `RestClient::Resource`'s `post` method.
    # @return [Object] an instance of a class determined by `type`.  For example, if `type` is
    #   `'user'`, the class will be `Conjur::User`.
    def standard_create(host, type, id = nil, options = nil)
      log do |logger|
        logger << "Creating #{type}"
        logger << " #{id}" if id
        unless options.blank?
          logger << " with options #{options.to_json}"
        end
      end
      options ||= {}
      options[:id] = id if id
      resp = RestClient::Resource.new(host, credentials)[type.to_s.pluralize].post(options)
      "Conjur::#{type.to_s.classify}".constantize.build_from_response(resp, credentials)
    end

    # @api private
    #
    # Fetch a list of assets by sending a GET request to the URL for resources of the given `type`.
    #
    # @param [String] host the url of the service (for example, https://conjur.host.com/api)
    # @param [String] type the asset `kind` (for example, 'user', 'group')
    # @param [Hash] options options to pass through to `RestClient::Resource`'s `post` method.
    # @return [Array<Object>] an array of instances of the asset class determined by `type`.  For example, if
    #   `type` is `'group'`, and array of `Conjur::Group` instances will be returned.
    def standard_list(host, type, options)
      JSON.parse(RestClient::Resource.new(host, credentials)[type.to_s.pluralize].get(options)).collect do |item|
        # Note that we don't want to fully_escape the ids below -- methods like #layer, #host, etc don't expect
        # ids to be escaped, and will escape them again!.
        if item.is_a? String  # lists w/o details are just list of ids 
          send(type,item)
        else                  # list w/ details consists of hashes
          send(type, item['id']).tap { |obj| obj.attributes=item }
        end
      end
    end

    # @api private
    #
    # Fetch details of an asset by sending a GET request to its URL.
    #
    # @param [String] host the url of the service (for example, https://conjur.host.com/api)
    # @param [String] type the asset `kind` (for example, 'user', 'group')
    # @param [String, nil] id the id of the asset to show
    # @return [Object] an instance of a class determined by `type`.  For example, if `type` is
    #   `'user'`, the class will be `Conjur::User`.
    def standard_show(host, type, id)
      "Conjur::#{type.to_s.classify}".constantize.new(host, credentials)[ [type.to_s.pluralize, fully_escape(id)].join('/') ]
    end
  end
end
