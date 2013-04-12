module Conjur
  class Secret < RestClient::Resource
    include ActsAsAsset
    
    def value
      self['value'].get.body
    end
  end
end
