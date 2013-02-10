module Conjur
  class Secret < RestClient::Resource
    include Exists
    include HasIdentifier
    include ActsAsResource
    include HasAttributes
    
    def value
      self['/value'].get.body
    end
  end
end
