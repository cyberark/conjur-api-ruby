module Conjur
  module ActsAsRole
    def role
      require 'conjur/role'
      Conjur::Role.new("#{Conjur::Authz::API.host}/roles/#{path_escape roleid}", self.options)
    end
  end
end