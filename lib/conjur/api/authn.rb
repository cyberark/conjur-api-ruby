require 'conjur/user'

# Fails for the CLI client because it has no slosilo key
#require 'rest-client'

#RestClient.add_before_execution_proc do |req, params|
#  require 'slosilo'
#  req.extend Slosilo::HTTPRequest
#  req.keyname = :authn
#end

module Conjur
  class API
    class << self
      # Perform login by Basic authentication.
      def login username, password
        if Conjur.log
          Conjur.log << "Logging in #{username} via Basic authentication\n"
        end
        RestClient::Resource.new(Conjur::Authn::API.host, user: username, password: password)['/users/login'].get
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
        JSON::parse(RestClient::Resource.new(Conjur::Authn::API.host)["/users/#{path_escape username}/authenticate"].post password, content_type: 'text/plain').tap do |token|
          raise InvalidToken.new unless token_valid?(token)
        end
      end
      
      def token_valid? token
        require 'slosilo'
        key = Slosilo[:authn]
        if key
          key.token_valid? token
        else
          raise KeyError, "authn key not found in Slosilo keystore"
        end
      end
    end

    def create_authn_user login, password = nil, options = {}
      log do |logger|
        logger << "Creating authn user #{login}"
      end
      RestClient::Resource.new(Conjur::Authn::API.host, credentials)['/users'].post(options.merge(login: login, password: password))
    end
  end
end
