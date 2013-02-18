module Conjur
  module ActsAsRole
    def role
      require 'conjur/role'
      Conjur::Role.new("#{Conjur::Authz::API.host}/roles/#{path_escape roleid}", options)
    end
  end
end