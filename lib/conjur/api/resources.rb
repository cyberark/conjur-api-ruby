require 'conjur/resource'

module Conjur
  class API
    def resource kind, identifier, location = host
      Resource.new("#{location}/#{kind}/#{escape identifier}", credentials)
    end
  end
end
