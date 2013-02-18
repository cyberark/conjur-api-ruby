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
      def login user, password
        if Conjur.log
          Conjur.log << "Logging in "
          Conjur.log << user
          Conjur.log << "\n"
        end
        RestClient::Resource.new(Conjur::Authn::API.host, user: user, password: password)['/users/login'].get
      end

      def authenticate user, password
        if Conjur.log
          Conjur.log << "Authenticating "
          Conjur.log << user
          Conjur.log << "\n"
        end
        JSON::parse(RestClient::Resource.new(Conjur::Authn::API.host)["/users/#{path_escape user}/authenticate"].post password, content_type: 'text/plain').tap do |token|
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
        logger << "Creating authn user "
        logger << login
      end
      RestClient::Resource.new(Conjur::Authn::API.host, credentials)['/users'].post(options.merge(login: login, password: password))
    end
  end
end
