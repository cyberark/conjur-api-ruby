module Conjur
  module HasId
    # NOTE: affected by migration to flat ids?
    def to_json(options = {})
      { id: id }
    end
  
    def id
      path_components[2..-1].join('/')
    end    
  end
end
