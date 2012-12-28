module Conjur
  class Role < RestClient::Resource
    def create
      self.put
    end
    
    def all
      JSON.parse self["/all"].get
    end
    
    def grant(member, admin_option = false)
      self["/members/#{escape member}?admin_option=#{admin_option}"].put
    end
  end
end