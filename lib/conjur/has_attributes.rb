module Conjur
  module HasAttributes
    def attributes=(a); @attributes = a; end
    def attributes
      return @attributes if @attributes
      @attributes = JSON.parse(get.body)
    end
    
    protected
    
    def fetch
      self.attributes = JSON.parse(get)
    end
  end
end