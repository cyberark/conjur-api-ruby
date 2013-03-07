module Conjur
  class Role < RestClient::Resource
    include Exists
    include HasId
    
    def create(options = {})
      log do |logger|
        logger << "Creating role #{id}"
        unless options.empty?
          logger << " with options #{options.to_json}"
        end
      end
      self.put(options)
    end
    
    def all(options = {})
      JSON.parse(self["/all"].get(options)).collect do |id|
        Role.new("#{Conjur::Authz::API.host}/roles/#{path_escape id}", self.options)
      end
    end
    
    def grant_to(member, admin_option = false, options = {})
      log do |logger|
        logger << "Granting role #{id} to #{member}"
        if admin_option
          logger << " with admin option"
        end
        unless options.empty?
          logger << " and extended options #{options.to_json}"
        end
      end
      self["/members/#{path_escape member}?admin_option=#{query_escape admin_option}"].put(options)
    end

    def revoke_from(member, options = {})
      log do |logger|
        logger << "Revoking role #{id} from #{member}"
        unless options.empty?
          logger << " with options #{options.to_json}"
        end
      end
      self["/members/#{path_escape member}"].delete(options)
    end

    def permitted?(resource_kind, resource_id, privilege, options = {})
      self["/permitted?resource_kind=#{query_escape resource_kind}&resource_id=#{query_escape resource_id}&privilege=#{query_escape privilege}"].get(options)
      true
    rescue RestClient::ResourceNotFound
      false
    end
  end
end