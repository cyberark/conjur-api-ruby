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
    
    protected
    
    def fetch
      @attributes = JSON.parse(get.body)
    end
  end
end