module Conjur
  class Resource < RestClient::Resource
    def kind
      match_path(1)
    end

    def identifier
      match_path(2)
    end
    
    def create
      self.put({}, content_type: :json)
    end

    def delete
      self.delete
    end

    def exists?(options = {})
      begin
        self.head(options)
        true
      rescue RestClient::ResourceNotFound
        false
      end
    end
    
    def permit(privilege, role, options = {})
      self["/permissions?operation=grant&privilege=#{privilege}&role=#{escape role}"].post(options)
    end
    
    def deny(privilege, role, options = {})
      self["/permissions?operation=revoke&privilege=#{privilege}&role=#{escape role}"].post(options)
    end
    
    def permitted?(role, privilege)
      roles = Role.expand(role)
      !self["/permissions"].find{|p| p['privilege'] == privilege && roles.include?(p['role']) }.nil?
    end
    
    protected
    
    def match_path(index)
      require 'uri'
      match = URI.parse(self.url).path.match(/^\/([^\/]+)\/([^\/]+)(?:\/|$)/)
      require 'uri'
      URI.unescape(match[index])
    end
  end
end