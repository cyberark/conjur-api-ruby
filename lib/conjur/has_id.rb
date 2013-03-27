module Conjur
  module HasId
    def id
      path_components[-1]
    end    
  end
end