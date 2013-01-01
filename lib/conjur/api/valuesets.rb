require 'conjur/valueset'
require 'conjur/value'

module Conjur
  class API
    def valueset identifier, location = host
      Valueset.new("#{location}/valuesets/#{escape identifier}", credentials)
    end
  end
end
