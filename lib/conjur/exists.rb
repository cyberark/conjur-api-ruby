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
  # Provides an `exists?` method for things that may or may not exist.
  #
  #
  # Most conjur assets returned by `api.asset_name` methods (e.g., {Conjur::API#group}, {Conjur::API#user})
  # may or may not exist.  The {Conjur::Exists#exists?} method lets you determine whether or not such assets
  # do in fact exist.
  module Exists

    # Check whether this asset exists by performing a HEAD request to its URL.
    #
    # This method will return false if the asset doesn't exist.
    #
    # @example
    #   does_not_exist = api.user 'does-not-exist' # This returns without error.
    #
    #   # this is wrong!
    #   owner = does_not_exist.ownerid # raises RestClient::ResourceNotFound
    #
    #   # this is right!
    #   owner = if does_not_exist.exists?
    #     does_not_exist.ownerid
    #    else
    #       nil # or some sensible default
    #    end
    #
    # @param [Hash] options included for compatibility: **don't use this argument**!
    # @return [Boolean] does it exist?
    def exists?(options = {})
      begin
        self.head(options)
        true
      rescue RestClient::Forbidden
        true
      rescue RestClient::ResourceNotFound
        false
      end
    end
  end
end