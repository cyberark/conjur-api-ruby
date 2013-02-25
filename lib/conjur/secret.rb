module Conjur
  class Secret < RestClient::Resource
    include ActsAsResource
    include HasAttributes
    include Exists
    include HasId
    
    def value
      self['/value'].get.body
    end
  end
end
