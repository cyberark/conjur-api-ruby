module Conjur
  module Core
    class API < Conjur::API
      class << self
        def conjur_account
          info['account'] or raise "No account field in #{info.inspect}"
        end
        
        def info
          @info ||= JSON.parse RestClient::Resource.new(Conjur::Core::API.host)['info'].get
        end
        
        def host
          ENV['CONJUR_CORE_URL'] || default_host
        end
        
        def default_host
          case Conjur.env
          when 'test', 'development'
            "http://localhost:#{Conjur.service_base_port + 200}"
          else
            "https://core-#{Conjur.account}-conjur.herokuapp.com"
          end
        end
      end
    end
  end
end

require 'conjur/api/hosts'
require 'conjur/api/secrets'
require 'conjur/api/users'
require 'conjur/api/groups'
require 'conjur/api/variables'
