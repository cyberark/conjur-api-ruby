module Conjur
  class Group < RestClient::Resource
    include ActsAsResource
    include ActsAsRole
    include HasId
    
    def roleid
      "group:#{id}"
    end
  end
end
