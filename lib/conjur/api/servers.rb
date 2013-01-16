require 'conjur/server'

module Conjur
  class API
    def create_server options
      resp = RestClient::Resource.new("#{Conjur::Core::API.host}/servers", credentials).post(options)
      Server.new(resp.headers[:location], credentials)
    end
    
    def server identifier
      Server.new("#{Conjur::Core::API.host}/servers/#{escape identifier}", credentials)
    end
  end
end
