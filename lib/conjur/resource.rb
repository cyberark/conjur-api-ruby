module Conjur
  class Resource < RestClient::Resource
    include Exists
    include HasAttributes
    
    def kind
      match_path(0..0)
    end

    def identifier
      match_path(1..-1)
    end
    
    def create(options = {})
      log do |logger|
        logger << "Creating resource #{kind} : #{identifier}"
        unless options.empty?
          logger << " with options #{options.to_json}"
        end
      end
      self.put(options)
    end

    # Lists roles that have a specified permission on the resource.
    def permitted_roles(permission, options = {})
      JSON.parse RestClient::Resource.new(Conjur::Authz::API.host, self.options)["roles/allowed_to/#{permission}/#{path_escape kind}/#{path_escape identifier}"].get(options)
    end
    
    # Changes the owner of a resource
    def give_to(owner, options = {})
      self.put(options.merge(owner: owner))
    end

    def delete(options = {})
      log do |logger|
        logger << "Deleting resource #{kind} : #{identifier}"
        unless options.empty?
          logger << " with options #{options.to_json}"
        end
      end
      super.delete(options)
    end

    def permit(privilege, role, options = {})
      eachable(privilege).each do |p|
        log do |logger|
          logger << "Permitting #{p} on resource #{kind} : #{identifier} by #{role}"
          unless options.empty?
            logger << " with options #{options.to_json}"
          end
        end
        
        self["?grant&privilege=#{query_escape p}&role=#{query_escape role}"].post(options)
      end
    end
    
    def deny(privilege, role, options = {})
      eachable(privilege).each do |p|
        log do |logger|
          logger << "Denying #{p} on resource #{kind} : #{identifier} by #{role}"
          unless options.empty?
            logger << " with options #{options.to_json}"
          end
        end
        self["?revoke&privilege=#{query_escape p}&role=#{query_escape role}"].post(options)
      end
    end
    
    protected
    
    def eachable(item)
      item.respond_to?(:each) ? item : [ item ]
    end
    
    def match_path(range)
      require 'uri'
      tokens = URI.parse(self.url).path[1..-1].split('/')[range]
      tokens.map{|t| URI.unescape(t)}.join('/')
    end
  end
end