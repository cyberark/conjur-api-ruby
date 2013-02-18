require 'conjur/secret'

module Conjur
  class API
    def create_secret(value, options = {})
      log do |logger|
        logger << "Creating secret "
        logger << value
      end
      resp = RestClient::Resource.new(Conjur::Core::API.host, credentials)['/secrets'].post(options.merge(value: value))
      Secret.new(resp.headers[:location], credentials).tap do |secret|
        log do |logger|
          logger << "Created secret "
          logger << secret.id
        end
      end
    end
    
    def secret id
      Secret.new("#{Conjur::Core::API.host}/secrets/#{path_escape id}", credentials)
    end
  end
end
