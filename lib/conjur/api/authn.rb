require 'conjur/user'

module Conjur
  class API
    class << self
      def login user, password
        RestClient::Resource.new(Conjur::Authn::API.host, user, password)['/users/login'].get
      end

      def user login
        User.new(Conjur::Authn::API.host)["/users/#{escape login}"]
      end
    end
  end
end
