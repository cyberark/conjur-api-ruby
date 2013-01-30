module Conjur
  class Role < RestClient::Resource
    include Exists
    include HasIdentifier
    
    def create
      self.put("")
    end
    
    def all
      JSON.parse(self["/all"].get).collect do |id|
        Role.new("#{Conjur::Authz::API.host}/roles/#{path_escape id}", options)
      end
    end
    
    def grant(member, admin_option = false)
      self["/members/#{path_escape member}?admin_option=#{query_escape admin_option}"].put("")
    end

    def permitted?(resource_kind, resource_id, privilege)
      self["/permitted?resource_kind=#{query_escape resource_kind}&resource_id=#{query_escape resource_id}&privilege=#{query_escape privilege}"].get
    end
  end
end