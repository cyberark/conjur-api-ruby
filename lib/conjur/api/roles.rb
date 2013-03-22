require 'conjur/role'

module Conjur
  class API
    def create_role(role, options = {})
      role(role).tap do |r|
        r.create(options)
      end
    end

    def role role
      paths = path_escape(role).split(':')
      path = [ paths[0], 'roles', paths[1..-1].join(':') ].flatten.join('/')
      Role.new(Conjur::Authz::API.host, credentials)[path]
    end
  end
end
