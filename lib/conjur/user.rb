module Conjur
  class InvalidToken < Exception
  end
  
  class User < RestClient::Resource
    def authenticate password
      JSON::parse(self["/authenticate"].post password, content_type: 'text/plain').tap do |token|
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
end
