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
  class InvalidToken < Exception
  end

  # This class represents a {http://developer.conjur.net/reference/services/directory/user Conjur User}.
  class User < RestClient::Resource
    include ActsAsAsset
    include ActsAsUser

    # Using a method instead of an alias here to make the docs look nicer :-/ - jjm

    # This method is simply an alias for {#id}.  It returns the user's *unqualified* id, which is referred to as
    # `login` here because it can be used to login to Conjur.
    # @return [String] the login for this user
    def login; id end

    # Assign new attributes to the user.
    #
    # If a user with the given `:uidnumber` already exists, this method will raise `RestClient::Forbidden`, with
    # the response body providing additional details if possible.
    #
    # ### Permissions
    # You must be a member of the user's role to update the uidnumber.
    # You must have update permission on the user's resource or be the user to
    # update CIDR restrictions.
    #
    # @note Updating `uidnumber` requires Conjur server version 4.3 or later.
    # @note Updating `cidr` requires Conjur server version 4.6 or later.
    #
    # @param [Hash] options attributes to change
    # @option options [FixNum] :uidnumber the new uidnumber for this user.
    # @option options [Array<String, IPAddr>] :cidr the network restrictions for this user. Requires Conjur server version 4.6 or later
    # @return [void]
    # @raise [RestClient::Conflict] if the uidnumber is already in use
    # @raise [ArgumentError] if uidnumber or cidr aren't valid
    def update options
      if uidnumber = options[:uidnumber]
        # Currently the server raises a 400 Bad Request if uidnumber is missing, require it here
        raise ArgumentError, "options[:uidnumber] must be a Fixnum" unless uidnumber.kind_of?(Fixnum)
        self.put(options)
      end

      if cidr = options[:cidr]
        set_cidr_restrictions cidr
      end
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
