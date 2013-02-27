module Conjur
  class Role < RestClient::Resource
    include Exists
    include HasId
    
    def create
      self.put("")
    end
    
    def all
      JSON.parse(self["/all"].get).collect do |id|
        Role.new("#{Conjur::Authz::API.host}/roles/#{path_escape id}", options)
      end
    end
    
    def grant_to(member, admin_option = false)
      log do |logger|
        logger << "Granting role #{id} to #{member}"
        if admin_option
          logger << " with admin option"
        end
      end
      self["/members/#{path_escape member}?admin_option=#{query_escape admin_option}"].put("")
    end

    def revoke_from(member)
      log do |logger|
        logger << "Revoking role #{id} from #{member}"
      end
      self["/members/#{path_escape member}"].delete
    end

    def permitted?(resource_kind, resource_id, privilege)
      self["/permitted?resource_kind=#{query_escape resource_kind}&resource_id=#{query_escape resource_id}&privilege=#{query_escape privilege}"].get
      true
    rescue RestClient::ResourceNotFound
      false
    end
  end
end