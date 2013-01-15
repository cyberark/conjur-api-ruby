require 'conjur/server'

module Conjur
  class API
    def create_server options
      resp = self['/servers'].post(options)
      server(nil, resp.headers[:location]) if resp.code == 201
    end
    
    def server identifier
      Server.new("#{Conjur::Core::API.host}/servers/#{escape identifier}", credentials)
    end
  end
end
