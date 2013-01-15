require 'conjur/value'

module Conjur
  class API
    def value identifier
      Value.new("#{Conjur::Core::API.host}/values/#{escape identifier}", credentials)
    end
  end
end
