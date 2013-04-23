require 'conjur/user'

module Conjur
  class API
    class << self
      # Perform login by Basic authentication.
      def login username, password
        if Conjur.log
          Conjur.log << "Logging in #{username} via Basic authentication\n"
        end
        RestClient::Resource.new(Conjur::Authn::API.host, user: username, password: password)['users/login'].get
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
        JSON::parse(RestClient::Resource.new(Conjur::Authn::API.host)["users/#{fully_escape username}/authenticate"].post password, content_type: 'text/plain')
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
      JSON.parse RestClient::Resource.new(Conjur::Authn::API.host, credentials)['users'].post(options.merge(login: login))
    end
  end
end
