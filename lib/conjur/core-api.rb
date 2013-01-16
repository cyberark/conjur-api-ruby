
require 'conjur/api/servers'
require 'conjur/api/values'

module Conjur
  module Core
    class API < Conjur::API
      class << self
        def host
          ENV['CONJUR_CORE_URL'] || default_host
        end
        
        def default_host
          case Conjur.env
          when 'test', 'development'
            "http://localhost:#{Conjur.service_base_port + 300}"
          else
            "https://conjur-core-#{Conjur.stack}.herokuapp.com"
          end
        end
      end
    end
  end
end
