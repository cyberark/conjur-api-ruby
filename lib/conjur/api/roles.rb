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

    def current_role
      role_from_username username
    end

    def role_from_username username
      role(role_name_from_username username)
    end
    
    def role_name_from_username username = self.username
      tokens = username.split('/')
      if tokens.size == 1
        [ 'user', username ].join(':')
      else
        [ tokens[0], tokens[1..-1].join('/') ].join(':')
      end
    end
  end
end
