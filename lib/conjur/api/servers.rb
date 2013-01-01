require 'conjur/server'

module Conjur
  class API
    def create_server options
      resp = self['/servers'].post(options)
      server(nil, resp.headers[:location]) if resp.code == 201
    end
    
    def server identifier, location = host
      location = "#{location}/servers/#{escape identifier}" if identifier
      Server.new(location, credentials)
    end
  end
end
