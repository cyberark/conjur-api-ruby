module Conjur
  class Secret < RestClient::Resource
    include ActsAsResource
    include Exists
    include HasId
    
    def value
      self['/value'].get.body
    end
  end
end
