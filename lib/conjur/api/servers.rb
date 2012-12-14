require 'conjur/server'

module Conjur
  class API
    def create_server options
      resp = post '/servers', options
      server(resp.headers[:location]) if resp.code == 201
    end
    
    def server location = host
      Server.new(location, credentials)
    end
  end
end
