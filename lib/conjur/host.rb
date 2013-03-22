module Conjur
  class Host < RestClient::Resource
    include Exists
    include HasId
    include HasIdentifier
    include HasAttributes
    include ActsAsUser
    
    def roleid
      "host:#{id}"
    end
    
    def enrollment_url
      log do |logger|
        logger << "Fetching enrollment_url for #{id}"
      end
      self['enrollment_url'].head{|response, request, result| response }.headers[:location]
    end
  end
end
