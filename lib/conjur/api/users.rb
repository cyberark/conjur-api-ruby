module Conjur
  class API
    def create_user(login, options = {})
      log do |logger|
        logger << "Creating user "
        logger << login
      end
      resp = RestClient::Resource.new(Conjur::Core::API.host, credentials)['/users'].post(options.merge(login: login))
      User.new(resp.headers[:location], credentials)
    end

    def user login
      User.new(Conjur::Core::API.host)["/users/#{path_escape login}"]
    end
  end
end