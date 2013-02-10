require 'conjur/host'

module Conjur
  class API
    def create_host options
      resp = RestClient::Resource.new("#{Conjur::Core::API.host}/hosts", credentials).post(options)
      Host.new(resp.headers[:location], credentials)
    end
    
    def host id
      Host.new("#{Conjur::Core::API.host}/hosts/#{path_escape id}", credentials)
    end
  end
end
