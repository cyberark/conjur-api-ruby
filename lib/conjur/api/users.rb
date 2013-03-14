require 'conjur/user'

module Conjur
  class API
    def create_user(login, options = {})
      standard_create Conjur::Core::API.host, :user, nil, options.merge(login: login)
    end

    def user login
      standard_show Conjur::Core::API.host, :user, login
    end
  end
end