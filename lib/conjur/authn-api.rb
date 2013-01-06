require 'conjur/api'
require 'conjur/api/authn'

module Conjur
  module Authn
    class API < Conjur::API
      class << self
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
