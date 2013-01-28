module Conjur
  class Value < RestClient::Resource
    include Exists
    include HasIdentifier
    include ActsAsResource
    
    def read
      self['/download'].get.body
    end
  end
end
