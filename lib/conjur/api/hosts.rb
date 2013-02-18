require 'conjur/host'

module Conjur
  class API
    def create_host options
      log do |logger|
        logger << "Creating host"
      end
      resp = RestClient::Resource.new("#{Conjur::Core::API.host}/hosts", credentials).post(options)
      Host.new(resp.headers[:location], credentials).tap do |host|
        log do |logger|
          logger << "Created host "
          logger << host.id
        end
      end
    end
    
    def host id
      Host.new("#{Conjur::Core::API.host}/hosts/#{path_escape id}", credentials)
    end
  end
end
