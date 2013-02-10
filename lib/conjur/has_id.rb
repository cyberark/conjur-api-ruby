module Conjur
  module HasId
    def id
      require 'uri'
      URI.unescape URI.parse(self.url).path.split('/')[-1]
    end    
  end
end