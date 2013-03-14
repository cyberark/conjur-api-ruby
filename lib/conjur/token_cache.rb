module Conjur
  # Cache API tokens. The cache key is the authentication hostname and the username.
  # Tokens are cached for a short period of time; long enough to save on server trips
  # but not long enough to worry about tokens expiring.
  class TokenCache
    @@tokens = Hash.new
    
    class << self
      def fetch(username, api_key)
        key = [ Conjur::Authn::API.host, username ]
        token = @@tokens[key]
        if token.nil? || expired?(token)
          if username && api_key
            store(token = Conjur::API.authenticate(username, api_key))
          elsif token.nil?
            raise "Token is nil and no api_key is available to create it"
          else
            $stderr.puts "Token is expired and no api_key is available to renew it"
          end
        end
        token
      end
      
      def store(token)
        username = token['data']
        raise "No data in token" unless username
        raise "Expecting string username in token" unless username.is_a?(String)
        key = [ Conjur::Authn::API.host, username ]
        @@tokens[key] = token
      end
      
      protected
      
      # Expire tokens after 1 minute, even though they are valid for longer.
      def expired?(token, expiry = 1 * 60)
        Time.parse(token["timestamp"]) + expiry < Time.now
      end
    end
  end
end