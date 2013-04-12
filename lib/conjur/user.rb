module Conjur
  class InvalidToken < Exception
  end
  
  class User < RestClient::Resource
    include ActsAsAsset
    include ActsAsUser
    
    alias login id
  end
end
