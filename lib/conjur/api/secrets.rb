require 'conjur/secret'

module Conjur
  class API
    def create_secret(value, options = {})
      resp = RestClient::Resource.new(Conjur::Core::API.host, credentials)['/secrets'].post(options.merge(value: value))
      Secret.new(resp.headers[:location], credentials)
    end
    
    def secret identifier
      Secret.new("#{Conjur::Core::API.host}/secrets/#{path_escape identifier}", credentials)
    end
  end
end
