require 'conjur/variable'

module Conjur
  class API
    def create_variable(mime_type, kind, options = {})
      log do |logger|
        logger << "Creating #{mime_type} variable #{kind}"
        if options
          logger << " with options #{options.inspect}"
        end
      end
      resp = RestClient::Resource.new(Conjur::Core::API.host, credentials)['variables'].post(options.merge(mime_type: mime_type, kind: kind))
      Variable.new(resp.headers[:location], credentials).tap do |variable|
        log do |logger|
          logger << "Created variable "
          logger << variable.id
        end
      end
    end
    
    def variable id
      Variable.new("#{Conjur::Core::API.host}/variables/#{path_escape id}", credentials)
    end
  end
end
