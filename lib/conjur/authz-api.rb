module Conjur
  module Authz
    class API < Conjur::API
      class << self
        def host
          ENV['CONJUR_AUTHZ_URL'] || default_host
        end
        
        def default_host
          case Conjur.env
          when 'test', 'development'
            "http://localhost:#{Conjur.service_base_port + 100}"
          else
            "https://authz-#{Conjur.stack}-conjur.herokuapp.com"
          end
        end
      end
    end
  end
end

require 'conjur/api/roles'
require 'conjur/api/resources'
