require 'conjur/role_grant'

module Conjur
  class Role < RestClient::Resource
    include Exists
    include PathBased

    def identifier
      match_path(3..-1)
    end
    
    alias id identifier
    
    def roleid
      [ account, kind, identifier ].join(':')
    end
    
    def create(options = {})
      log do |logger|
        logger << "Creating role #{kind}:#{identifier}"
        unless options.empty?
          logger << " with options #{options.to_json}"
        end
      end
      self.put(options)
    end
    
    def all(options = {})
      JSON.parse(self["?all"].get(options)).collect do |id|
        id = [ id['account'], id['id'] ].join(':')
        Role.new(Conjur::Authz::API.host, self.options)[Conjur::API.parse_role_id(id).join('/')]
      end
    end
    
    def grant_to(member, admin_option = false, options = {})
      log do |logger|
        logger << "Granting role #{identifier} to #{member}"
        if admin_option
          logger << " with admin option"
        end
        unless options.empty?
          logger << " and extended options #{options.to_json}"
        end
      end
      self["?members&member=#{query_escape member}&admin_option=#{query_escape admin_option}"].put(options)
    end

    def revoke_from(member, options = {})
      log do |logger|
        logger << "Revoking role #{identifier} from #{member}"
        unless options.empty?
          logger << " with options #{options.to_json}"
        end
      end
      self["?members&member=#{query_escape member}"].delete(options)
    end

    def permitted?(resource_kind, resource_id, privilege, options = {})
      self["?check&resource_kind=#{query_escape resource_kind}&resource_id=#{query_escape resource_id}&privilege=#{query_escape privilege}"].get(options)
      true
    rescue RestClient::ResourceNotFound
      false
    end
    
    def members
      JSON.parse(self["?members"].get(options)).collect do |json|
        RoleGrant.parse_from_json(json, self.options)
      end
    end
  end
end