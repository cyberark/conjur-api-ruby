module Conjur
  module ActsAsRole
    def roleid
      self.attributes['roleid'] or raise "roleid attribute not found"
    end
    
    def role
      require 'conjur/role'
      Conjur::Role.new(Conjur::Authz::API.host, self.options)[Conjur::API.parse_role_id(self.roleid).join('/')]
    end
  end
end