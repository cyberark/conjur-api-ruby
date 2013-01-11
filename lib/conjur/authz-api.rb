require 'conjur/api'

require 'conjur/api/roles'
require 'conjur/api/resources'

module Conjur
  module Authz
    class API < Conjur::API
      class << self
        def host
          ENV['CONJUR_AUTHZ_URL'] || default_host
        end
        
        def default_host
          case Conjur.env
          when 'test', 'cucumber', 'development'
            "http://localhost:#{Conjur.service_base_port + 100}"
          else
            "https://conjur-authz-#{Conjur.stack}.herokuapp.com"
          end
        end
      end
    end
  end
end
