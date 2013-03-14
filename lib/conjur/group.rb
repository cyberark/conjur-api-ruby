module Conjur
  class Group < RestClient::Resource
    include ActsAsResource
    include ActsAsRole
    include HasId
    include HasAttributes
    
    def roleid
      "group:#{id}"
    end
  end
end
