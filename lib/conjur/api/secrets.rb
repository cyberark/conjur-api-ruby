require 'conjur/secret'

module Conjur
  class API
    def create_secret(value, options = {})
      standard_create Conjur::Core::API.host, :secret, nil, options.merge(value: value)
    end
    
    def secret id
      standard_show Conjur::Core::API.host, :secret, id
    end
  end
end
