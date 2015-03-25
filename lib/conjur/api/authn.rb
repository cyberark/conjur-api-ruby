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
require 'conjur/user'

module Conjur
  class API
    class << self
      # Perform login by Basic authentication.
      def login username, password
        if Conjur.log
          Conjur.log << "Logging in #{username} via Basic authentication\n"
        end
        Conjur::REST.new(Conjur::Authn::API.host,
                         user: username, password: password)['users/login'].get
      end

      # Perform login by CAS authentication.
      def login_cas username, password, cas_api_url
        if Conjur.log
          Conjur.log << "Logging in #{username} via CAS authentication\n"
        end
        require 'cas_rest_client'
        client = CasRestClient.new(:username => username, :password => password, :uri => [ cas_api_url, 'v1', 'tickets' ].join('/'), :use_cookies => false)
        client.get("#{Conjur::Authn::API.host}/users/login").body
      end

      def authenticate username, password
        if Conjur.log
          Conjur.log << "Authenticating #{username}\n"
        end
        JSON.parse(Conjur::REST.new(Conjur::Authn::API.host)\
                  ["users/#{fully_escape username}/authenticate"]\
                  .post password, content_type: 'text/plain')
      end
      
      def update_password username, password, new_password
        if Conjur.log
          Conjur.log << "Updating password for #{username}\n"
        end
        Conjur::REST.new(Conjur::Authn::API.host,
                          user: username, password: password
                        )['users/password'].put new_password
      end
    end

    # Options:
    # +password+
    #
    # Response:
    # +login+
    # +api_key+
    def create_authn_user login, options = {}
      log do |logger|
        logger << "Creating authn user #{login}"
      end
      JSON.parse Conjur::REST.new(Conjur::Authn::API.host, credentials)\
          ['users'].post(options.merge(login: login))
    end
  end
end
