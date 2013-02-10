module Conjur
  module HasIdentifier
    def self.included(base)
      base.instance_eval do
        include HasAttributes
      end
    end
    
    def identifier
      attributes['identifier']
    end    
  end
end