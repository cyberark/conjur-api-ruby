module Conjur
  class Secret < RestClient::Resource
    include Exists
    include HasIdentifier
    include ActsAsResource
    
    def value
      self['/download'].get.body
    end
  end
end
