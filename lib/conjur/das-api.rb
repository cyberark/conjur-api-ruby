require 'conjur/api'

module Conjur
  module DAS
    class API < Conjur::API
      class << self
        def host
          ENV['CONJUR_DAS_URL'] || default_host
        end
        
        def default_host
          case Conjur.env
          when 'test', 'cucumber', 'development'
            "http://localhost:#{Conjur.service_base_port + 200}"
          else
            "https://conjur-das-#{Conjur.stack}.herokuapp.com"
          end
        end
      end
    end
  end
end
