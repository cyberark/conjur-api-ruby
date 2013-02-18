require 'conjur/role'

module Conjur
  class API
    def create_role(role, options = {})
      log do |logger|
        logger << "Creating role "
        logger << role
      end
      RestClient::Resource.new(Conjur::Authz::API.host, credentials)["/roles/#{path_escape role}"].put(options)
      Role.new(role, credentials)
    end

    def role identifier
      Role.new("#{Conjur::Authz::API.host}/roles/#{path_escape identifier}", credentials)
    end
  end
end
