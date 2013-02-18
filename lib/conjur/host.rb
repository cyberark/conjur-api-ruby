module Conjur
  class Host < RestClient::Resource
    include Exists
    include HasId
    include HasIdentifier
    include HasAttributes
    include ActsAsUser
    
    def enrollment_url
      log do |logger|
        logger << "Fetching enrollment_url for "
        logger << id
      end
      self['/enrollment_url'].head{|response, request, result| response }.headers[:location]
    end
  end
end
