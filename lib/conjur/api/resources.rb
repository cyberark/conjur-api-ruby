require 'conjur/resource'

module Conjur
  class API
    def resource kind, identifier
      Resource.new("#{Conjur::Authz::API.host}/#{kind}/#{path_escape identifier}", credentials)
    end
  end
end
