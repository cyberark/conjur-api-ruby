module Conjur
  class Role < RestClient::Resource
    include Exists
    include HasIdentifier
    
    def create
      self.put("")
    end
    
    def all
      JSON.parse(self["/all"].get).collect do |id|
        Role.new("#{Conjur::Authz::API.host}/roles/#{escape id}", options)
      end
    end
    
    def grant(member, admin_option = false)
      self["/members/#{escape member}?admin_option=#{admin_option}"].put("")
    end

    def permitted?(resource_kind, resource_id, privilege)
      self["/permitted?resource_kind=#{escape resource_kind}&resource_id=#{escape resource_id}&privilege=#{escape privilege}"].get
    end
  end
end