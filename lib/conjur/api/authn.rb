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

      # The Conjur {http://developer.conjur.net/reference/services/authentication/login.html login}
      #   operation exchanges a username and a password for an api key.  The api key
      #   is preferable for storage and use in code, as it can be rotated and has far greater entropy than
      #   a user memorizable password.
      #
      #  * Note that this method works only for {http://developer.conjur.net/reference/services/directory/user Users}. While
      #   {http://developer.conjur.net/reference/services/directory/hosts Hosts} possess Conjur identities, they do not
      #   have passwords.
      #  * If you pass an api key to this method instead of a password, it will simply return the API key.
      #  * This method uses Basic Auth to send the credentials.
      #
      # @example
      #   bob_api_key = Conjur::API.login('bob', 'bob_password')
      #   bob_api_key == Conjur::API.login('bob', bob_api_key)  # => true
      #
      # @param [String] username The `username` or `login` for the
      #   {http://developer.conjur.net/reference/services/directory/user Conjur User}.
      # @param [String] password The `password` or `api key` to authenticate with.
      # @return [String] the API key.
      # @raise [RestClient::Exception] when the request fails or the identity provided is invalid.
      def login username, password
        if Conjur.log
          Conjur.log << "Logging in #{username} via Basic authentication\n"
        end
        RestClient::Resource.new(Conjur::Authn::API.host, user: username, password: password)['users/login'].get
      end

      # TODO I have NO idea how to document login_cas!

      # This method logs in via CAS.  It is similar to the {.login} method, the only difference being that
      # you need a `cas_api_url`, provided by the administrator of your `CAS` service.
      #
      # @see .login
      # @param [String] username the Conjur username
      # @param [String] password the Conjur password
      # @param [String] cas_api_url the url of the CAS service
      # @return [String] a `CAS` ticket
      def login_cas username, password, cas_api_url
        if Conjur.log
          Conjur.log << "Logging in #{username} via CAS authentication\n"
        end
        require 'cas_rest_client'
        client = CasRestClient.new(:username => username, :password => password, :uri => [ cas_api_url, 'v1', 'tickets' ].join('/'), :use_cookies => false)
        client.get("#{Conjur::Authn::API.host}/users/login").body
      end

      # The Conjur {http://developer.conjur.net/reference/services/authentication/authenticate.html authenticate} operation
      #    exchanges Conjur credentials for a token.  The token can then be used to authenticate further API calls.
      #
      # You will generally not need to use this method, as the API manages tokens automatically for you.
      #
      # @param [String] username The username or host id for which we want a token
      # @param [String] password The password or api key
      # @return [String] A JSON formatted authentication token.
      def authenticate username, password
        if Conjur.log
          Conjur.log << "Authenticating #{username}\n"
        end
        JSON.parse(RestClient::Resource.new(Conjur::Authn::API.host)["users/#{fully_escape username}/authenticate"].post password, content_type: 'text/plain')
      end

      def authenticate_local username
        if Conjur.log
          Conjur.log << "Authenticating #{username} with authn-local\n"
        end
        require 'net_http_unix'
        client = NetX::HTTPUnix.new('unix:///run/authn-local/.socket')
        resp = client.request(Net::HTTP::Post.new("/users/#{fully_escape username}/authenticate"))
        JSON.parse(resp.body)
      end


      # Change a user's password.  To do this, you must have the user's current password.  This does not change or rotate
      #   api keys.  However, you *can*  use the user's api key as the *current* password, if the user was not created
      #   with a password.
      #
      # @param [String] username the name of the user whose password we want to change
      # @param [String] password the user's *current* password *or* api key
      # @param [String] new_password the new password for the user.
      # @return [void]
      def update_password username, password, new_password
        if Conjur.log
          Conjur.log << "Updating password for #{username}\n"
        end
        RestClient::Resource.new(Conjur::Authn::API.host, user: username, password: password)['users/password'].put new_password
      end

      #@!endgroup

      #@!group Password and API key management

      # Rotate the currently authenticated user's API key by generating and returning a new one.
      # The old API key is no longer valid after calling this method.  You must have the user's current
      # API key or password to perform this operation.  This method *does not* affect the user's password.
      #
      # @note If the user does not have a password, the returned API key will be the **only** way to authenticate as
      #   the user.  Therefore, you'd best save it.
      #
      # @note This feature requires version 4.6 of the Conjur appliance.
      #
      # @param [String] username the name of the user whose password we want to change
      # @param [String] password the user's current password *or* api key
      # @return [String] the new API key for the user
      def rotate_api_key username, password
        if Conjur.log
          Conjur.log << "Rotating API key for self (#{username})\n"
        end

        RestClient::Resource.new(
              Conjur::Authn::API.host,
              user: username,
              password: password
        )['users/api_key'].put('').body
      end

      #@!endgroup
    end

    # @api private
    # This is used internally to create a user that we can log in as without creating
    # an actual user in the directory, as with #create_user.
    def create_authn_user login, options = {}
      log do |logger|
        logger << "Creating authn user #{login}"
      end
      JSON.parse RestClient::Resource.new(Conjur::Authn::API.host, credentials)['users'].post(options.merge(login: login))
    end
  end
end
