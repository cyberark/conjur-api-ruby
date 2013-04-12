module Conjur
  module ActsAsRole
    def roleid
      [ conjur_account, role_kind, id ].join(':')
    end
    
    def role_kind
      self.class.name.split('::')[-1].underscore
    end
    
    def conjur_account
      Conjur::Core::API.conjur_account
    end
    
    def role
      require 'conjur/role'
      Conjur::Role.new(Conjur::Authz::API.host, self.options)[Conjur::API.parse_role_id(self.roleid).join('/')]
    end
  end
end