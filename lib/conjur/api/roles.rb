require 'conjur/role'

module Conjur
  class API
    def role identifier, location = host
      Role.new("#{location}/roles/#{escape identifier}", credentials)
    end
  end
end
