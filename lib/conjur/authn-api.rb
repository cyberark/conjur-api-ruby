module Conjur
  module Authn
    class API < Conjur::API
      class << self
        def host
          ENV['CONJUR_AUTHN_URL'] || default_host
        end
        
        def default_host
          case Conjur.env
          when 'test', 'development'
            "http://localhost:#{Conjur.service_base_port}"
          else
            "https://authn-#{Conjur.account}-conjur.herokuapp.com"
          end
        end
      end
    end
  end
end

require 'conjur/api/authn'
