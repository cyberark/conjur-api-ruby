require 'conjur/value'

module Conjur
  class API
    def create_value(value)
      resp = RestClient::Resource.new(Conjur::Core::API.host, credentials)['/values'].post(value: value)
      Value.new(resp.headers[:location], credentials)
    end
    
    def value identifier
      Value.new("#{Conjur::Core::API.host}/values/#{escape identifier}", credentials)
    end
  end
end
