module Conjur
  module HasId
    def to_json(options = {})
      { id: id }
    end
  
    def id
      path_components[2..-1].join('/')
    end    
  end
end
