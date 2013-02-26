module Conjur
  module HasAttributes
    def attributes=(a); @attributes = a; end
    def attributes
      return @attributes if @attributes
      fetch
    end
    
    def save
      self.put(attributes.to_json)
    end
    
    # Reload the attributes. This action can be used to guarantee a current view of the entity in the case
    # that it has been modified by an update method or by an external party.
    def refresh
      fetch
    end
    
    protected
    
    def invalidate(&block)
      yield
      @attributes = nil
    end
    
    def fetch
      @attributes = JSON.parse(get.body)
    end
  end
end
