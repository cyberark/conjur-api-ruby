require 'conjur/valueset'
require 'conjur/value'

module Conjur
  class API
    def valueset identifier, location = Conjur::Authz::API.host
      Valueset.new("#{location}/valuesets/#{escape identifier}", credentials)
    end
  end
end
