require 'conjur/role'

module Conjur
  class API
    def create_role(role, options = {})
      log do |logger|
        logger << "Creating role #{account}/#{role}"
      end
      RestClient::Resource.new(Conjur::Authz::API.host, credentials)["roles/#{path_escape role}"].put(options)
      role(role)
    end

    def role role
      Role.new(Conjur::Authz::API.host, credentials)["roles/#{path_escape role}"]
    end
  end
end
