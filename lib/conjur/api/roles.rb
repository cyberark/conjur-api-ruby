require 'conjur/role'

module Conjur
  class API
    def create_role(role, options = {})
      role(role).tap do |r|
        r.create(options)
      end
    end

    def role role
      Role.new(Conjur::Authz::API.host, credentials)[self.class.parse_role_id(role).join('/')]
    end
  end
end
