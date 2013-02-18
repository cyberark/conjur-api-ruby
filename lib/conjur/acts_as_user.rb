module Conjur
  module ActsAsUser
    def self.included(base)
      base.instance_eval do
        include ActsAsRole
      end
    end
    
    def roleid
      id
    end
  end
end