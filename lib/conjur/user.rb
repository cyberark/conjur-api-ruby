module Conjur
  class InvalidToken < Exception
  end
  
  class User < RestClient::Resource
    include HasId
    include ActsAsResource
    include ActsAsUser
    
    alias login id
  end
end
