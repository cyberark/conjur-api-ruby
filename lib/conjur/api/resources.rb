require 'conjur/resource'

module Conjur
  class API
    def create_resource(identifier, options = {})
      resource(identifier).tap do |r|
        r.create(options)
      end
    end
    
    def resource identifier
      Resource.new(Conjur::Authz::API.host, credentials)[path_escape(identifier)]
    end
  end
end
