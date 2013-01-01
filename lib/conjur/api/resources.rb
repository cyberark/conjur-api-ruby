require 'conjur/resource'

module Conjur
  class API
    def resource kind, identifier, location = Conjur::Authz::API.host
      Resource.new("#{location}/#{kind}/#{escape identifier}", credentials)
    end
  end
end
