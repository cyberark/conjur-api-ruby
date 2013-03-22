require 'conjur/resource'

module Conjur
  class API
    def create_resource(identifier, options = {})
      resource(identifier).tap do |r|
        r.create(options)
      end
    end
    
    def resource identifier
      paths = path_escape(identifier).split(':')
      path = [ paths[0], 'resources', paths[1], paths[2..-1].join(':') ].flatten.join('/')
      Resource.new(Conjur::Authz::API.host, credentials)[path]
    end
  end
end
