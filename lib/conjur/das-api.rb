require 'conjur/api'
require 'conjur/api/das'

module Conjur
  module DAS
    class API < Conjur::API
      class << self
        def host
          ENV['CONJUR_DAS_URL'] || default_host
        end
        
        def default_host
          case Conjur.env
          when 'test', 'development'
            "http://localhost:#{Conjur.service_base_port + 200}"
          else
            "https://das-#{Conjur.stack}-conjur.herokuapp.com"
          end
        end
      end
    end
  end
end
