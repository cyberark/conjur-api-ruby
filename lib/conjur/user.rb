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
  class InvalidToken < Exception
  end
  
  class User < RestClient::Resource
    include ActsAsAsset
    include ActsAsUser

    alias login id


    # Assign new attributes to the user.  Currently, this method only lets you change the
    # `:uidnumber` attribute.
    #
    # If a user with the given `:uidnumber` already exists, this method will raise `RestClient::Forbidden`, with
    # the response body providing additional details if possible.
    #
    # ### Permissions
    # You must be a member of the user's role to call this method.
    #
    # @note This feature requires Conjur server version 4.3 or later.
    #
    # @param [Hash] options attributes to change
    # @option options [FixNum] :uidnumber the new uidnumber for this user.  This option *must* be present.
    # @return [void]
    # @raise [RestClient::Conflict] if the uidnumber is already in use
    # @raise [ArgumentError] if uidnumber isn't a `Fixnum` or isn't present in `options`
    def update options
      # Currently the server raises a 400 Bad Request if uidnumber is missing, require it here
      raise ArgumentError "options[:uidnumber] is required" unless uidnumber = options[:uidnumber]
      raise ArgumentError, "options[:uidnumber] must be a Fixnum" unless uidnumber.kind_of?(Fixnum)
      self.put(options)
    end

    # Get the user's uidnumber, which is used by LDAP and SSH login, among other things.
    #
    # ### Permissions
    # You must have the `'show'` permission on the user's resource to call this method
    #
    # @note This feature requires Conjur server version 4.3 or later.
    #
    # @return [Fixnum] the uidnumber
    # @raise [RestClient::Forbidden] if you don't have permission to `show` the user.
    def uidnumber
      attributes['uidnumber']
    end

    # Set the user's uidnumber, which is used by LDAP and SSH login.
    #
    # ### Permissions
    # You must be a member of the user's role to call this method.
    #
    # @note This feature requires Conjur server version 4.3 or later.
    #
    # @param [Fixnum] uidnumber the new uidnumber
    # @return [void]
    # @raise [RestClient::Conflict] if the uidnumber is already in use.
    def uidnumber= uidnumber
      update uidnumber: uidnumber
    end
  end
end
