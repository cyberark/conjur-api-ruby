require 'conjur/api'

module Conjur
  module Authn
    class API < Conjur::API
      class << self
        def get_key user, pass
          RestClient::Resource.new(host, user, pass)['user/api_key'].get
        end
  
        def host
          ENV['CONJUR_AUTHN_URL'] || default_host
        end
        
        def default_host
          "http://localhost:5000"
        end
      end
    end
  end
end
