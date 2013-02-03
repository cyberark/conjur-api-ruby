require 'conjur/host'

module Conjur
  class API
    def create_host options
      resp = RestClient::Resource.new("#{Conjur::Core::API.host}/hosts", credentials).post(options)
      Host.new(resp.headers[:location], credentials)
    end
    
    def host identifier
      Host.new("#{Conjur::Core::API.host}/hosts/#{path_escape identifier}", credentials)
    end
  end
end
