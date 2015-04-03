#
# Copyright (C) 2013 Conjur Inc
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
##
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
require 'conjur/user'

module Conjur
  class API
    #@!group Directory: Users

    # Create a {http://developer.conjur.net/reference/services/directory/user Conjur User}.  Conjur users
    # are identities for humans.
    #
    # When you create a user for the first time, the returned object will have an `api_key` field.  You can then
    # use this to set a password for the user if you want to.  Note that when the user is fetched later with the {#user}
    # method, it **will not have an api_key**.  Use it or lose it.
    #
    # ### Permissions
    # Any authenticated role may call this method.
    #
    # @example Create a user 'alice' and set her password to 'frogger'
    #   alice = api.create_user 'alice', password: 'frogger'
    #
    #   # Now we can login as 'alice'.
    #   alice_api = Conjur::API.new_from_key 'alice', 'frogger'
    #   alice_api.current_role # => 'conjur:user:alice'
    #
    # @example Create a user and save her `api_key` for later use
    #    alice = api.create_user 'alice' # note that we're not giving a password
    #    save_api_key 'alice', alice.api_key
    #
    # @param [String] login the login for the new user
    # @param [Hash] options options for user creation
    # @option options [String] :acting_as Qualified id of a role to perform the action as
    # @option options [String, Integer] :uidnumber UID number to assign to the new user.  If not given, one will be generated.
    # @option options [String] :password when present, the user will be given a password in addition to a randomly
    #   generated api key.
    # @return [Conjur::User] an object representing the new user
    # @raise [RestClient::Conflict] If the user already exists, or a user with the given uidnumber exists.
    def create_user(login, options = {})
      standard_create Conjur::Core::API.host, :user, nil, options.merge(login: login)
    end

    # Return an object representing a user with the given login. The {Conjur::User} object returned
    # may or may not exist.  You can check whether it exists with the {Conjur::Exists#exists?} method.
    #
    # The returned {Conjur::User} will *not* have an api_key.
    #
    # ### Permissions
    # Any authenticated role may call this method.
    #
    # @param [String] login the user's login
    # @return [Conjur::User] an object representing the user
    def user login
      standard_show Conjur::Core::API.host, :user, login
    end

    # @api private
    #
    # @note In the future, further options for search may be added, but presently this only supports uid search.
    #
    # Find users by uidnumber.
    #
    #
    # When a user is created it is assigned a uid number.  When the uid number is not specified when creating the user,
    # a sequential uid number will be generated, starting at 1000.  uidnumbers are used when synchronizing with LDAP directories
    # and to assign a UNIX user id number when using {http://developer.conjur.net/tutorials/ssh/conjur-ssh.html Conjur SSH login}.
    #
    # ### Note
    # Although users are uniquely identified by their uidnumber, the result of this method is an array of user ids for compatibility
    # reasons.
    #
    # ### Permissions
    # Only roles of which you are a member will be returned
    #
    # @param [Hash] options query to send
    # @option options [String, Integer] :uidnumber (required) the uidnumber to search for
    # @return [Array<String>] a one element array containing the users login.
    def find_users options
      JSON.parse( RestClient::Resource.new(Conjur::Core::API.host, credentials)["users/search?#{options.to_query}"].get )
    end

    #@!endgroup
  end
end
