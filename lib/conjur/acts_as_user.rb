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
  end
end
