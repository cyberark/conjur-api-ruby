
require 'conjur/api/servers'
require 'conjur/api/valuesets'

module Conjur
  module Core
    class API < Conjur::API
      class << self
        def host
          ENV['CONJUR_CORE_URL'] || default_host
        end
        
        def default_host
          "http://localhost:5200"
        end
      end
    end
  end
end
