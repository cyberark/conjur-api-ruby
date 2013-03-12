require 'conjur/user'

module Conjur
  class API
    def create_user(login, options = {})
      log do |logger|
        logger << "Creating user "
        logger << login
      end
      resp = JSON.parse RestClient::Resource.new(Conjur::Core::API.host, credentials)['/users'].post(options.merge(login: login))
      user(resp['login']).tap do |u|
        log do |logger|
          logger << "Created user #{u.login}"
        end
        u.attributes = resp
      end
    end

    def user login
      User.new(Conjur::Core::API.host, credentials)["/users/#{path_escape login}"]
    end
  end
end