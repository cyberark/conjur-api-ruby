require 'conjur/role'

module Conjur
  class API
    def role identifier
      Role.new("#{Conjur::Authz::API.host}/roles/#{path_escape identifier}", credentials)
    end
  end
end
