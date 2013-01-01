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
          "http://localhost:5100"
        end
      end
    end
  end
end
