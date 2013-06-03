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
    
    def grant_to(member, *args)
      if Conjur::API::VERSION < "3.0.0"
        options = args[-1]
        if args.length > 1
          warning = "WARNING: Deprecated arguments to grant_to. Please put admin_option in the options hash."
          options[:admin_option] = args[0]
        end

        unless options.nil? || options.is_a?(Hash)
          warning = "WARNING: Deprecated arguments to grant_to. Please put admin_option in the options hash."
          options = { admin_option: options }
        end
      else
        raise "Please remove the deprecated API in 3.0 and change the method signature to grant_to(member, options)"
      end

      log do |logger|
        logger << warning if warning
        logger << "Granting role #{identifier} to #{member}"
        unless options.blank?
          logger << " with options #{options.to_json}"
        end
      end
      self["?members&member=#{query_escape member}"].put(options)
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