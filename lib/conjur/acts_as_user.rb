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
module Conjur
  # This module provides methods for things that are like users (specifically, those that have
  # api keys).
  module ActsAsUser
    include ActsAsRole

    # Returns a newly created user's api_key.
    #
    # @note this method can only be called on newly created user-like things (those returned from, for example,)
    #   {Conjur::API#create_user}.
    #
    # @return [String] the api key
    # @raise [Exception] when the object isn't newly created.
    def api_key
      attributes['api_key'] or raise "api_key is only available on a newly created #{self.class.name.downcase}"
    end

    # Create an api logged in as this user-like thing.
    #
    # @note As with {#api_key}, this method only works on newly created instances.
    # @see #api_key
    # @return [Conjur::API] an api logged in as this user-like thing.
    def api
      Conjur::API.new_from_key login, api_key
    end

    # Rotate this user's API key.  You must have `update` permission on the user to do so.
    #
    # @note You will not be able to access the API key returned by this method later, so you should
    #   probably hang onto it it.
    #
    # @note You cannot rotate your own API key with this method.  To do so, use `Conjur::API.rotate_api_key`
    #
    # @note This feature requires a Conjur appliance running version 4.6 or higher.
    #
    # @return [String] the new API key for this user.
    def rotate_api_key
      path = "users/api_key?id=#{fully_escape login}"
      RestClient::Resource.new(Conjur::Authn::API.host, options)[path].put('').body
    end

    # Set login network restrictions for the user.
    #
    # @param [Array<String, IPAddr>] networks which allow logging in. Set to empty to remove restrictions
    def set_cidr_restrictions networks
      authn_user = RestClient::Resource.new(Conjur::Authn::API.host, options)\
          ["users?id=#{fully_escape login}"]

      # we need use JSON here to be able to PUT an empty array
      params = { cidr: [*networks].map(&CIDR.method(:validate)).map(&:to_s) }
      authn_user.put params.to_json, content_type: :json
    end
  end
end
