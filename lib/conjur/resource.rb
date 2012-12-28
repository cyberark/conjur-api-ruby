module Conjur
  class Resource < RestClient::Resource
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
  end
end