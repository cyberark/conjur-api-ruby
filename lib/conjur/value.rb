module Conjur
  class Value < RestClient::Resource
    include Exists
    include HasAttributes
    
    def create(name, bytes, key)
      uuid, size = DAS.upload bytes, name, key
      
      self.post(name: name, uuid: uuid, size: size, key: key)
    end
  end
end
