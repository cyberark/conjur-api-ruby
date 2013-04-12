module Conjur
  module HasOwner
    def self.included(base)
      base.instance_eval do
        include HasAttributes
      end
    end
    
    def userid
      attributes['userid']
    end    
    
    def ownerid
      attributes['ownerid']
    end    
  end
end