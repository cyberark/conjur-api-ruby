require 'conjur/variable'

module Conjur
  class API
    def create_variable(mime_type, kind, options = {})
      standard_create Conjur::Core::API.host, :variable, nil, options.merge(mime_type: mime_type, kind: kind)
    end
    
    def variable id
      standard_show Conjur::Core::API.host, :variable, id
    end
  end
end
