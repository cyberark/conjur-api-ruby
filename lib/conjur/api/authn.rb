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
require 'conjur/user'

module Conjur
  class API
    class << self
      #@!group Authentication Methods

      # Exchanges a username and a password for an api key.  The api key
      #   is preferable for storage and use in code, as it can be rotated and has far greater entropy than
      #   a user memorizable password.
      #
      #  * Note that this method works only for {Conjur::User}s. While
      #   {Conjur::Host}s are roles, they do not have passwords.
      #  * If you pass an api key to this method instead of a password, it will simply return the API key.
      #  * This method uses Basic Auth to send the credentials.
      #
      # @example
      #   bob_api_key = Conjur::API.login('mycorp', 'bob', 'bob_password')
      #   bob_api_key == Conjur::API.login('mycorp', 'bob', bob_api_key)  # => true
      #
      # @param [String] username The `username` or `login` for the
      #   {http://developer.conjur.net/reference/services/directory/user Conjur User}.
      # @param [String] password The `password` or `api key` to authenticate with.
      # @param [String] account The organization account.
      # @return [String] the API key.
      # @raise [RestClient::Exception] when the request fails or the identity provided is invalid.
      def login username, password, account: Conjur.configuration.account
        if Conjur.log
          Conjur.log << "Logging in #{username} to account #{account} via Basic authentication\n"
        end
        RestClient::Resource.new(Conjur.configuration.authn_url, user: username, password: password)['authn'][fully_escape account]['login'].get
      end

      # Exchanges Conjur the API key (refresh token) for an access token.  The access token can 
      # then be used to authenticate further API calls.
      #
      # @param [String] username The username or host id for which we want a token
      # @param [String] api_key The api key
      # @param [String] account The organization account.
      # @return [String] A JSON formatted authentication token.
      def authenticate username, api_key, account: Conjur.configuration.account
        account ||= Conjur.configuration.account
        if Conjur.log
          Conjur.log << "Authenticating #{username} to account #{account}\n"
        end
        JSON::parse(RestClient::Resource.new(Conjur.configuration.authn_url)['authn'][fully_escape account][fully_escape username]['authenticate'].post api_key, content_type: 'text/plain')
      end

      # Change a user's password.  To do this, you must have the user's current password.  This does not change or rotate
      #   api keys.  However, you *can*  use the user's api key as the *current* password, if the user was not created
      #   with a password.
      #
      # @param [String] username the name of the user whose password we want to change
      # @param [String] password the user's *current* password *or* api key
      # @param [String] new_password the new password for the user.
      # @param [String] account The organization account.
      # @return [void]
      def update_password username, password, new_password, account: Conjur.configuration.account
        if Conjur.log
          Conjur.log << "Updating password for #{username} in account #{account}\n"
        end
        RestClient::Resource.new(Conjur.configuration.authn_url, user: username, password: password)['authn'][fully_escape account]['password'].put new_password
      end

      #@!endgroup

      #@!group Password and API key management

      # Rotate the currently authenticated user or host API key by generating and returning a new one.
      # The old API key is no longer valid after calling this method.  You must have the current
      # API key or password to perform this operation.  This method *does not* affect a user's password.
      #
      # @param [String] username the name of the user or host whose API key we want to change
      # @param [String] password the user's current api key
      # @param [String] account The organization account.
      # @return [String] the new API key
      def rotate_api_key username, password, account: Conjur.configuration.account
        if Conjur.log
          Conjur.log << "Rotating API key for self (#{username} in account #{account})\n"
        end

        RestClient::Resource.new(
              Conjur.configuration.authn_url,
              user: username,
              password: password
        )['authn'][fully_escape account]['api_key'].put('').body
      end

      #@!endgroup
    end
  end
end
