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
      Slosilo[:authn].token_valid? token
    end
  end
end