require 'conjur/user'

# Fails for the CLI client because it has no slosilo key
#require 'rest-client'

#RestClient.add_before_execution_proc do |req, params|
#  require 'slosilo'
#  req.extend Slosilo::HTTPRequest
#  req.keyname = :authn
#end

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
