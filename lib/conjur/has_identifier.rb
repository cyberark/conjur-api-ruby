module Conjur
  module HasIdentifier
    def identifier
      require 'uri'
      URI.unescape URI.parse(self.url).path.split('/')[-1]
    end    
  end
end